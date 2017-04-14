/*****************************************************************************
 * Media Library
 *****************************************************************************
 * Copyright (C) 2015 Hugo Beauzée-Luyssen, Videolabs
 *
 * Authors: Hugo Beauzée-Luyssen<hugo@beauzee.fr>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#if HAVE_CONFIG_H
# include "config.h"
#endif

#include "factory/FileSystemFactory.h"
#include "filesystem/IDirectory.h"
#include "filesystem/IFile.h"
#include "logging/Logger.h"
#include "utils/Filename.h"

#if defined(__linux__) || defined(__APPLE__)
# include "filesystem/unix/Directory.h"
# include "filesystem/unix/File.h"
# include "filesystem/unix/Device.h"
#elif defined(_WIN32)
# include "filesystem/win32/Directory.h"
# include "filesystem/win32/File.h"
# include "filesystem/win32/Device.h"
#else
# error No filesystem implementation for this architecture
#endif

#include "medialibrary/IDeviceLister.h"
#include "compat/Mutex.h"

namespace medialibrary
{

namespace factory
{

FileSystemFactory::FileSystemFactory( DeviceListerPtr lister )
    : m_deviceLister( lister )
{
    refreshDevices();
}

std::shared_ptr<fs::IDirectory> FileSystemFactory::createDirectory( const std::string& mrl )
{
    std::lock_guard<compat::Mutex> lock( m_mutex );
    const auto it = m_dirs.find( mrl );
    if ( it != end( m_dirs ) )
        return it->second;
    try
    {
        auto dir = std::make_shared<fs::Directory>( mrl, *this );
        m_dirs[mrl] = dir;
        return dir;
    }
    catch(const std::system_error& ex)
    {
        LOG_ERROR( "Failed to create fs::IDirectory for ", mrl, ": ", ex.what());
        return nullptr;
    }
}

std::shared_ptr<fs::IDevice> FileSystemFactory::createDevice( const std::string& uuid )
{
    auto lock = m_deviceCache.lock();

    auto it = m_deviceCache.get().find( uuid );
    if ( it != end( m_deviceCache.get() ) )
        return it->second;
    return nullptr;
}

std::shared_ptr<fs::IDevice> FileSystemFactory::createDeviceFromMrl( const std::string& mrl )
{
    auto lock = m_deviceCache.lock();
    std::shared_ptr<fs::IDevice> res;
    for ( const auto& p : m_deviceCache.get() )
    {
        if ( mrl.find( p.second->mountpoint() ) == 0 )
        {
            if ( res == nullptr || res->mountpoint().length() < p.second->mountpoint().length() )
                res = p.second;
        }
    }
    return res;
}

void FileSystemFactory::refreshDevices()
{
    {
        std::lock_guard<compat::Mutex> lock( m_mutex );
        m_dirs.clear();
    }
    auto lock = m_deviceCache.lock();
    if ( m_deviceCache.isCached() == false )
        m_deviceCache = DeviceCacheMap{};
    m_deviceCache.get().clear();
    LOG_INFO( "Refreshing devices from IDeviceLister" );
    auto devices = m_deviceLister->devices();
    if ( devices.empty() == true )
    {
        LOG_WARN( "No device detected." );
        return;
    }
    for ( const auto& d : devices )
    {
        const auto& uuid = std::get<0>( d );
        const auto& mountpoint = std::get<1>( d );
        const auto removable = std::get<2>( d );
        LOG_INFO( "Caching device ", uuid, " mounted on ", mountpoint, ". Removable: ", removable ? "true" : "false" );
        m_deviceCache.get().emplace( uuid, std::make_shared<fs::Device>( uuid, mountpoint, removable ) );
    }
    return;
}

bool FileSystemFactory::isMrlSupported( const std::string& path ) const
{
    return path.compare( 0, 7, "file://" ) == 0;
}

bool FileSystemFactory::isNetworkFileSystem() const
{
    return false;
}

}

}

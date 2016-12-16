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

#pragma once

#include <string>

namespace medialibrary
{

namespace fs
{
    class IFile
    {
    public:
        virtual ~IFile() = default;
        /// Returns the filename, including extension
        virtual const std::string& name() const = 0;
        /// Returns the path containing the file
        virtual const std::string& path() const = 0;
        /// Returns the entire path, plus filename
        virtual const std::string& fullPath() const = 0;
        virtual const std::string& extension() const = 0;
        virtual unsigned int lastModificationDate() const = 0;
        virtual unsigned int size() const = 0;
    };
}

}
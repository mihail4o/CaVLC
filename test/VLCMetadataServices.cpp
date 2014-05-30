#include "gtest/gtest.h"
#include <iostream>
#include <vlc/vlc.h>
#include <condition_variable>

#include "IMediaLibrary.h"
#include "IMetadataService.h"
#include "IFile.h"
#include "IAudioTrack.h"
#include "metadata_services/VLCMetadataService.h"

class ServiceCb : public IMetadataServiceCb
{
    public:
        std::condition_variable waitCond;
        std::mutex mutex;

        ServiceCb()
        {
        }

        virtual void updated( FilePtr )
        {
            waitCond.notify_all();
        }

        virtual void error( FilePtr, const std::string& error )
        {
            std::cerr << "Error: " << error << std::endl;
            FAIL();
        }
};

class VLCMetadataServices : public testing::Test
{
    public:
        static std::unique_ptr<IMediaLibrary> ml;
        static std::unique_ptr<ServiceCb> cb;
        static libvlc_instance_t* vlcInstance;

    protected:
        virtual void SetUp()
        {
            ml.reset( MediaLibraryFactory::create() );
            cb.reset( new ServiceCb );
            vlcInstance = libvlc_new( 0, NULL );
            auto vlcService = new VLCMetadataService( vlcInstance );

            vlcService->initialize( cb.get(), ml.get() );
            ml->addMetadataService( vlcService );
            bool res = ml->initialize( "test.db" );
            ASSERT_TRUE( res );
        }

        virtual void TearDown()
        {
            libvlc_release( vlcInstance );
            ml.reset();
            unlink("test.db");
        }
};

std::unique_ptr<IMediaLibrary> VLCMetadataServices::ml;
std::unique_ptr<ServiceCb> VLCMetadataServices::cb;
libvlc_instance_t* VLCMetadataServices::vlcInstance;

TEST_F( VLCMetadataServices, ParseAudio )
{
    std::unique_lock<std::mutex> lock( cb->mutex );
    auto file = ml->addFile( "/home/chouquette/samples/mr-zebra.mp3" );
    std::vector<AudioTrackPtr> tracks;
    cb->waitCond.wait( lock, [&]{ return file->audioTracks( tracks ) == true && tracks.size() > 0; } );

    SetUp();
    file = ml->file( "/home/chouquette/samples/mr-zebra.mp3" );
    bool res = file->audioTracks( tracks );
    ASSERT_TRUE( res );
    ASSERT_EQ( tracks.size(), 1u );
    auto track = tracks[0];
    ASSERT_EQ( track->codec(), "mpga" );
    ASSERT_EQ( track->bitrate(), 128000 );
    ASSERT_EQ( track->sampleRate(), 44100 );
    ASSERT_EQ( track->nbChannels(), 2 );
}

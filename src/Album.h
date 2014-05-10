#ifndef ALBUM_H
#define ALBUM_H

#include <sqlite3.h>

#include "IAlbum.h"

class Album : public IAlbum
{
    public:
        Album( sqlite3* dbConnection, sqlite3_stmt* stmt );
        Album( sqlite3* dbConnection );

        virtual const std::string& name();
        virtual unsigned int releaseYear();
        virtual const std::string& shortSummary();
        virtual const std::string& artworkUrl();
        virtual time_t lastSyncDate();

        static bool CreateTable( sqlite3* dbConnection );
        static Album* Fetch( sqlite3* dbConnection, unsigned int albumTrackId)

    protected:
        sqlite3* m_dbConnection;
        unsigned int m_id;
        std::string m_name;
        unsigned int m_releaseYear;
        std::string m_shortSummary;
        std::string m_artworkUrl;
        time_t m_lastSyncDate;

};

#endif // ALBUM_H

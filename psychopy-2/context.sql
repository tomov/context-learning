create database if not exists context;

use context;

create table data (
    id bigint auto_increment primary key,
    participant bigint,
    session bigint,
    mriMode varchar(50),
    isPractice int,
    expStart datetime,

    restaurantNames varchar(200), -- reshuffled
    foods varchar(200), -- reshuffled
    contextRole varchar(100),

    contextId int,
    cueId int,
    sick varchar(50),
    corrAns varchar(50),
    responseKey varchar(50),
     
    restaurant varchar(100),
    food varchar(100),
    
    roundId int,
    trialId int,
    trainOrTest varchar(50),

    stimOnset datetime(6),
    responseTime datetime(6),
    feedbackOnset datetime(6)
);

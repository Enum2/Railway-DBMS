SET @station_id = 0;
CALL AddStation('Visakhapatnam Junction', 'Visakhapatnam', @station_id);

SET @station_id = 0;
CALL AddStation('Madurai Junction', 'Madurai', @station_id);

SET @station_id = 0;
CALL AddStation('Tiruchirappalli Junction', 'Tiruchirappalli', @station_id);

SET @station_id = 0;
CALL AddStation('Gwalior Junction', 'Gwalior', @station_id);

SET @station_id = 0;
CALL AddStation('Siliguri Junction', 'Siliguri', @station_id);


SET @train_id = 0;
CALL AddTrain(
    'Visakhapatnam Express', 
    '12861', 
    'Visakhapatnam Junction', 
    'Chennai Central', 
    '17:00', 
    '07:30', 
    @train_id
);
SET @train_id = 0;
CALL AddTrain(
    'Madurai Superfast', 
    '12638', 
    'Madurai Junction', 
    'Chennai Central', 
    '22:00', 
    '06:30', 
    @train_id
);
SET @train_id = 0;
CALL AddTrain(
    'Gwalior Shatabdi', 
    '12002', 
    'Gwalior Junction', 
    'New Delhi', 
    '06:00', 
    '09:45', 
    @train_id
);
SET @train_id = 0;
CALL AddTrain(
    'Siliguri Intercity', 
    '15713', 
    'Siliguri Junction', 
    'Howrah Junction', 
    '16:30', 
    '04:45', 
    @train_id
);

SET @train_id = 0;
CALL AddTrain(
    'Tiruchirappalli Express', 
    '12696', 
    'Tiruchirappalli Junction', 
    'Chennai Central', 
    '20:00', 
    '03:30', 
    @train_id
);

CALL AddWeeklySchedules('12861', '2025-04-15', 4, '1,3,5');
CALL AddWeeklySchedules('12638', '2025-04-16', 3, '2,4,6');
CALL AddWeeklySchedules('12002', '2025-04-20', 2, '1,2,3,4,5,6,7');
CALL AddWeeklySchedules('15713', '2025-04-14', 5, '3,7');
CALL AddWeeklySchedules('12696', '2025-04-18', 6, '5');

CALL GenerateTrainRuns('2025-04-15', '2025-05-31');

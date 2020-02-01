-- phpMyAdmin SQL Dump
-- version 4.6.6deb5
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Feb 01, 2020 at 05:12 PM
-- Server version: 5.7.28-0ubuntu0.18.04.4
-- PHP Version: 7.2.24-0ubuntu0.18.04.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+05:30";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `TrainDb`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `activate_device` ()  NO SQL
INSERT INTO `ActiveDevices` (`device_id`, `device_tamper`, `device_status`, `geo_latitude`, `geo_longitude`, `time_last_updated`) VALUES ('BOLT20001', '0', '1', NULL, NULL, CURRENT_TIMESTAMP)$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `deactivate_device` ()  MODIFIES SQL DATA
UPDATE `Device_details` 
SET `ready` = '0'
WHERE `Device_details`.`device_id` = 'BOLT200001'$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `faulty_device` ()  NO SQL
UPDATE `Device_details` SET `ready` = '0' WHERE `Device_details`.`device_id` = 'BOLT200001'$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `fetch_active_devices` ()  READS SQL DATA
SELECT AD.device_id, AD.device_status, AD.time_last_updated from ActiveDevices as AD
WHERE AD.device_tamper = 0$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `fetch_active_device_with_api` ()  READS SQL DATA
BEGIN

if ( select NOT exists (select 1 from ActiveDevices) ) THEN

    select 'None';

ELSE

SELECT AD.device_id, DD.device_api_token
FROM ActiveDevices as AD
INNER JOIN Device_details as DD
ON AD.device_id = DD.device_id AND
AD.device_tamper != '1';

END IF;

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `fetch_idle_devices` ()  NO SQL
BEGIN

if ( select NOT exists (select 1 from Device_details) ) THEN

    select 'None';

ELSE

SELECT DD.device_id, DD.ready, DD.halting
FROM Device_details as DD
WHERE DD.ready = 1 
	AND 
    NOT EXISTS( SELECT * from ActiveDevices as AD WHERE AD.device_id = DD.device_id);

END IF;

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `fetch_ready_devices` ()  READS SQL DATA
BEGIN

if ( select NOT exists (select 1 from Device_details) ) THEN

    select 'None';

ELSE

SELECT *
FROM Device_details as DD
WHERE DD.ready = 1  
	AND DD.halting != 1
	AND 
    NOT EXISTS( SELECT * from ActiveDevices as AD WHERE AD.device_id = DD.device_id);

END IF;

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `fetch_subscribers` ()  READS SQL DATA
BEGIN

SELECT *
FROM device_BOLT200001_subscribers;

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `fetch_tampered_devices` ()  READS SQL DATA
SELECT AD.device_id, AD.time_last_updated
FROM ActiveDevices as AD 
WHERE AD.device_tamper = 1$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `get_tamper_report` ()  MODIFIES SQL DATA
SELECT subs.subscriber_sms_number, time_last_updated
FROM
device_BOLT200001_subscribers as subs
JOIN ActiveDevices as AD$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `halt_device` ()  MODIFIES SQL DATA
UPDATE `Device_details` SET `halting` = '1' WHERE `Device_details`.`device_id` = 'BOLT200001'$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `log_update` (IN `g_device_status` BOOLEAN, IN `g_message` CHAR(250), IN `g_tamper` BOOLEAN)  MODIFIES SQL DATA
BEGIN

INSERT INTO `device_BOLT200001_log` (`date_time_stamp`, `device_status`, `geo_longitude`, `geo_latitude`, `message`, `device_tamper`) VALUES (CURRENT_TIMESTAMP, g_device_status, NULL, NULL, g_message, g_tamper);

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `ready_device` ()  NO SQL
UPDATE `Device_details` SET `ready` = '1' WHERE `Device_details`.`device_id` = 'BOLT200001'$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `reset_device` ()  MODIFIES SQL DATA
BEGIN

DELETE FROM `ActiveDevices` WHERE `ActiveDevices`.`device_id` = 'BOLT200001';

UPDATE `Device_details` SET `ready` = '1' , `halting` = '0' WHERE `Device_details`.`device_id` = 'BOLT200001';

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `test_procedure` ()  MODIFIES SQL DATA
SELECT 'Something called test_procedure.'$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `update_device_log_msg` (IN `g_message` VARCHAR(256))  MODIFIES SQL DATA
INSERT INTO `device_BOLT200001_log` (`date_time_stamp`, `device_status`, `geo_longitude`, `geo_latitude`, `message`, `device_tamper`) VALUES (CURRENT_TIMESTAMP, NULL, NULL, NULL, g_message, NULL)$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `update_device_status` (IN `g_device_id` VARCHAR(10), IN `g_status` BOOLEAN, IN `g_tamper_status` BOOLEAN, IN `g_lat` DECIMAL(10,8), IN `g_lon` DECIMAL(11,8))  NO SQL
BEGIN

UPDATE ActiveDevices as AD
SET AD.device_status = g_status,
	AD.device_tamper = g_tamper_status,
    AD.geo_latitude = g_lat,
    AD.geo_longitude = g_lon,
	AD.time_last_updated = CURRENT_TIMESTAMP
WHERE AD.device_id = g_device_id;

END$$

CREATE DEFINER=`test_bot`@`localhost` PROCEDURE `update_status` (IN `g_status` BOOLEAN, IN `g_tamper` BOOLEAN)  MODIFIES SQL DATA
BEGIN
UPDATE ActiveDevices 
SET time_last_updated = CURRENT_TIMESTAMP, 
device_status = g_status,
device_tamper = g_tamper
;						
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `ActiveDevices`
--

CREATE TABLE `ActiveDevices` (
  `device_id` varchar(10) NOT NULL,
  `device_tamper` tinyint(1) NOT NULL COMMENT '0-No, 1-Yes',
  `device_status` tinyint(1) NOT NULL COMMENT '0-offline 1-online',
  `geo_latitude` decimal(10,8) DEFAULT NULL,
  `geo_longitude` decimal(11,8) DEFAULT NULL,
  `time_last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf32;

--
-- Dumping data for table `ActiveDevices`
--

INSERT INTO `ActiveDevices` (`device_id`, `device_tamper`, `device_status`, `geo_latitude`, `geo_longitude`, `time_last_updated`) VALUES
('BOLT200001', 1, 1, NULL, NULL, '2020-01-19 06:43:14');

-- --------------------------------------------------------

--
-- Table structure for table `device_BOLT200001_log`
--

CREATE TABLE `device_BOLT200001_log` (
  `date_time_stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `device_status` tinyint(1) DEFAULT NULL,
  `geo_longitude` decimal(11,8) DEFAULT NULL,
  `geo_latitude` decimal(10,8) DEFAULT NULL,
  `message` varchar(256) NOT NULL,
  `device_tamper` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf32;

--
-- Dumping data for table `device_BOLT200001_log`
--

INSERT INTO `device_BOLT200001_log` (`date_time_stamp`, `device_status`, `geo_longitude`, `geo_latitude`, `message`, `device_tamper`) VALUES
('2020-01-19 03:46:35', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 03:46:40', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:46:46', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:46:53', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:47:00', 1, NULL, NULL, 'Lock tampered', 1),
('2020-01-19 03:47:36', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 03:47:47', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 03:47:53', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:48:00', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:48:01', NULL, NULL, NULL, 'Halt by API', NULL),
('2020-01-19 03:48:10', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 03:48:18', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 03:48:22', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:48:28', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:48:29', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 03:48:31', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 03:48:35', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 03:48:37', NULL, NULL, NULL, 'Halt by API', NULL),
('2020-01-19 03:48:41', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 05:58:14', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 05:58:18', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 05:58:26', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 05:58:32', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 05:58:37', NULL, NULL, NULL, 'Halt by API', NULL),
('2020-01-19 05:58:51', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 05:59:22', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 05:59:24', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 05:59:31', 1, NULL, NULL, 'Lock tampered', 1),
('2020-01-19 05:59:56', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 06:38:52', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 06:38:54', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 06:39:00', 1, NULL, NULL, 'Lock tampered', 1),
('2020-01-19 06:40:34', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 06:42:06', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 06:42:10', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 06:42:17', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 06:42:24', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 06:42:27', NULL, NULL, NULL, 'Halt by API', NULL),
('2020-01-19 06:42:44', NULL, NULL, NULL, 'Reset By API', NULL),
('2020-01-19 06:42:55', 1, NULL, NULL, 'Lock Activated', 0),
('2020-01-19 06:43:01', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 06:43:08', 1, NULL, NULL, 'Routine Check', 0),
('2020-01-19 06:43:15', 1, NULL, NULL, 'Lock tampered', 1);

-- --------------------------------------------------------

--
-- Table structure for table `device_BOLT200001_subscribers`
--

CREATE TABLE `device_BOLT200001_subscribers` (
  `subscriber_id` int(11) NOT NULL,
  `subscriber_name` varchar(30) NOT NULL,
  `subcriber_email` varchar(30) NOT NULL,
  `subscriber_sms_number` char(13) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf32;

--
-- Dumping data for table `device_BOLT200001_subscribers`
--

INSERT INTO `device_BOLT200001_subscribers` (`subscriber_id`, `subscriber_name`, `subcriber_email`, `subscriber_sms_number`) VALUES
(101, 'test_human', 'abc@gmail.com', '+919998887776');

-- --------------------------------------------------------

--
-- Table structure for table `Device_details`
--

CREATE TABLE `Device_details` (
  `device_id` varchar(10) NOT NULL,
  `device_api_token` varchar(256) NOT NULL,
  `device_date_added` datetime NOT NULL,
  `credentials_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ready` tinyint(1) NOT NULL COMMENT 'Ready = 1, Tampered= 0',
  `halting` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf32;

--
-- Dumping data for table `Device_details`
--

INSERT INTO `Device_details` (`device_id`, `device_api_token`, `device_date_added`, `credentials_date_modified`, `ready`, `halting`) VALUES
('BOLT200001', 'xxxxx-xxxx-xxx-xxxx-xxxxxxx', '2020-01-16 07:30:16', '2020-01-16 07:30:16', 0, 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ActiveDevices`
--
ALTER TABLE `ActiveDevices`
  ADD PRIMARY KEY (`device_id`);

--
-- Indexes for table `device_BOLT200001_log`
--
ALTER TABLE `device_BOLT200001_log`
  ADD PRIMARY KEY (`date_time_stamp`);

--
-- Indexes for table `device_BOLT200001_subscribers`
--
ALTER TABLE `device_BOLT200001_subscribers`
  ADD PRIMARY KEY (`subscriber_id`);

--
-- Indexes for table `Device_details`
--
ALTER TABLE `Device_details`
  ADD PRIMARY KEY (`device_id`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

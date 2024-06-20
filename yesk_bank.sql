ALTER TABLE `users` ADD COLUMN `bankaccount` VARCHAR(255) NOT NULL DEFAULT '0';
ALTER TABLE `addon_account` ADD COLUMN `bankaccount` VARCHAR(255) NOT NULL DEFAULT '0';
CREATE TABLE `yesk_history` (
  `id` int(11) NOT NULL,
  `identifier` varchar(46) NOT NULL,
  `senderName` varchar(46) DEFAULT NULL,
  `sender` varchar(46) NOT NULL,
  `action` varchar(46) NOT NULL,
  `money` varchar(24) NOT NULL,
  `date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
ALTER TABLE `yesk_history` ADD PRIMARY KEY (`id`);
ALTER TABLE `yesk_history` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
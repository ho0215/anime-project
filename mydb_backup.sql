/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: mydb
-- ------------------------------------------------------
-- Server version	10.11.14-MariaDB-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `anime_anime`
--

DROP TABLE IF EXISTS `anime_anime`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `anime_anime` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `genre` varchar(100) NOT NULL,
  `synopsis` longtext NOT NULL,
  `image_url` varchar(200) NOT NULL,
  `score` double NOT NULL,
  `backdrop_url` varchar(200) DEFAULT NULL,
  `first_air_date` varchar(50) DEFAULT NULL,
  `original_title` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `api_id` (`api_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `anime_anime`
--

LOCK TABLES `anime_anime` WRITE;
/*!40000 ALTER TABLE `anime_anime` DISABLE KEYS */;
/*!40000 ALTER TABLE `anime_anime` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `anime_review`
--

DROP TABLE IF EXISTS `anime_review`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `anime_review` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `score` int(11) NOT NULL,
  `content` varchar(200) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `anime_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `anime_review_anime_id_4bfc82bd_fk_anime_anime_id` (`anime_id`),
  CONSTRAINT `anime_review_anime_id_4bfc82bd_fk_anime_anime_id` FOREIGN KEY (`anime_id`) REFERENCES `anime_anime` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `anime_review`
--

LOCK TABLES `anime_review` WRITE;
/*!40000 ALTER TABLE `anime_review` DISABLE KEYS */;
/*!40000 ALTER TABLE `anime_review` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_group`
--

DROP TABLE IF EXISTS `auth_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group`
--

LOCK TABLES `auth_group` WRITE;
/*!40000 ALTER TABLE `auth_group` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_group_permissions`
--

DROP TABLE IF EXISTS `auth_group_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group_permissions`
--

LOCK TABLES `auth_group_permissions` WRITE;
/*!40000 ALTER TABLE `auth_group_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_permission`
--

DROP TABLE IF EXISTS `auth_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_permission` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
INSERT INTO `auth_permission` VALUES
(1,'Can add log entry',1,'add_logentry'),
(2,'Can change log entry',1,'change_logentry'),
(3,'Can delete log entry',1,'delete_logentry'),
(4,'Can view log entry',1,'view_logentry'),
(5,'Can add permission',3,'add_permission'),
(6,'Can change permission',3,'change_permission'),
(7,'Can delete permission',3,'delete_permission'),
(8,'Can view permission',3,'view_permission'),
(9,'Can add group',2,'add_group'),
(10,'Can change group',2,'change_group'),
(11,'Can delete group',2,'delete_group'),
(12,'Can view group',2,'view_group'),
(13,'Can add user',4,'add_user'),
(14,'Can change user',4,'change_user'),
(15,'Can delete user',4,'delete_user'),
(16,'Can view user',4,'view_user'),
(17,'Can add content type',5,'add_contenttype'),
(18,'Can change content type',5,'change_contenttype'),
(19,'Can delete content type',5,'delete_contenttype'),
(20,'Can view content type',5,'view_contenttype'),
(21,'Can add session',6,'add_session'),
(22,'Can change session',6,'change_session'),
(23,'Can delete session',6,'delete_session'),
(24,'Can view session',6,'view_session'),
(25,'Can add goods',7,'add_goods'),
(26,'Can change goods',7,'change_goods'),
(27,'Can delete goods',7,'delete_goods'),
(28,'Can view goods',7,'view_goods'),
(29,'Can add anime',8,'add_anime'),
(30,'Can change anime',8,'change_anime'),
(31,'Can delete anime',8,'delete_anime'),
(32,'Can view anime',8,'view_anime'),
(33,'Can add comment',9,'add_comment'),
(34,'Can change comment',9,'change_comment'),
(35,'Can delete comment',9,'delete_comment'),
(36,'Can view comment',9,'view_comment'),
(37,'Can add post',10,'add_post'),
(38,'Can change post',10,'change_post'),
(39,'Can delete post',10,'delete_post'),
(40,'Can view post',10,'view_post'),
(41,'Can add message',12,'add_message'),
(42,'Can change message',12,'change_message'),
(43,'Can delete message',12,'delete_message'),
(44,'Can view message',12,'view_message'),
(45,'Can add chat room',11,'add_chatroom'),
(46,'Can change chat room',11,'change_chatroom'),
(47,'Can delete chat room',11,'delete_chatroom'),
(48,'Can view chat room',11,'view_chatroom'),
(49,'Can add wishlist',13,'add_wishlist'),
(50,'Can change wishlist',13,'change_wishlist'),
(51,'Can delete wishlist',13,'delete_wishlist'),
(52,'Can view wishlist',13,'view_wishlist'),
(53,'Can add work image',15,'add_workimage'),
(54,'Can change work image',15,'change_workimage'),
(55,'Can delete work image',15,'delete_workimage'),
(56,'Can view work image',15,'view_workimage'),
(57,'Can add creative work',14,'add_creativework'),
(58,'Can change creative work',14,'change_creativework'),
(59,'Can delete creative work',14,'delete_creativework'),
(60,'Can view creative work',14,'view_creativework'),
(61,'Can add goods report',16,'add_goodsreport'),
(62,'Can change goods report',16,'change_goodsreport'),
(63,'Can delete goods report',16,'delete_goodsreport'),
(64,'Can view goods report',16,'view_goodsreport'),
(65,'Can add user report',17,'add_userreport'),
(66,'Can change user report',17,'change_userreport'),
(67,'Can delete user report',17,'delete_userreport'),
(68,'Can view user report',17,'view_userreport'),
(69,'Can add review',18,'add_review'),
(70,'Can change review',18,'change_review'),
(71,'Can delete review',18,'delete_review'),
(72,'Can view review',18,'view_review');
/*!40000 ALTER TABLE `auth_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user`
--

DROP TABLE IF EXISTS `auth_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `password` varchar(128) NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL,
  `username` varchar(150) NOT NULL,
  `first_name` varchar(150) NOT NULL,
  `last_name` varchar(150) NOT NULL,
  `email` varchar(254) NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user`
--

LOCK TABLES `auth_user` WRITE;
/*!40000 ALTER TABLE `auth_user` DISABLE KEYS */;
INSERT INTO `auth_user` VALUES
(1,'pbkdf2_sha256$1200000$czqxGpDvWZkPG16a8uyvbE$tKIuRoAYg6vKils8swbSL1xnsnJggG7grTtdb8jlVtU=','2026-07-16 08:38:10.137936',0,'drseoyi','','','',0,1,'2026-07-10 07:42:07.832770'),
(2,'pbkdf2_sha256$1200000$xwSN0lsYeMmFTYUFA3oW0Y$mg0HoTO84bckG8x1MLjx0u2ylxttNT1Lg+2+yUh77HE=','2026-07-20 02:13:03.321055',1,'admin','','','admin@admin.com',1,1,'2026-07-10 08:46:25.672603'),
(3,'pbkdf2_sha256$1200000$GW5H0R2sTGE3oRu66RvbMo$2vmcuiPLhoQVk74UB/k+AysiwA83mFC8ocUezIK3MTY=','2026-07-13 06:05:46.589429',0,'dungmin29','','','',0,1,'2026-07-13 06:05:35.539435'),
(4,'pbkdf2_sha256$1200000$kWBl9yM9hfifaFySff8ffS$irBfDNaQFj+0wjInGerxjP5sH8LWO9RVSqTvkeSyNcc=','2026-07-13 07:04:12.674380',0,'a112','','','',0,1,'2026-07-13 07:04:04.689828');
/*!40000 ALTER TABLE `auth_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user_groups`
--

DROP TABLE IF EXISTS `auth_user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user_groups` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_groups_user_id_group_id_94350c0c_uniq` (`user_id`,`group_id`),
  KEY `auth_user_groups_group_id_97559544_fk_auth_group_id` (`group_id`),
  CONSTRAINT `auth_user_groups_group_id_97559544_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`),
  CONSTRAINT `auth_user_groups_user_id_6a12ed8b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user_groups`
--

LOCK TABLES `auth_user_groups` WRITE;
/*!40000 ALTER TABLE `auth_user_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user_user_permissions`
--

DROP TABLE IF EXISTS `auth_user_user_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user_user_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_user_permissions_user_id_permission_id_14a6b632_uniq` (`user_id`,`permission_id`),
  KEY `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user_user_permissions`
--

LOCK TABLES `auth_user_user_permissions` WRITE;
/*!40000 ALTER TABLE `auth_user_user_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_user_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `community_comment`
--

DROP TABLE IF EXISTS `community_comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `community_comment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `content` longtext NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `author_id` int(11) NOT NULL,
  `post_id` bigint(20) NOT NULL,
  `parent_comment_id` bigint(20) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `community_comment_author_id_51c65c2a_fk_auth_user_id` (`author_id`),
  KEY `community_comment_post_id_12b521a8_fk_community_post_id` (`post_id`),
  KEY `community_comment_parent_comment_id_67b09268_fk_community` (`parent_comment_id`),
  CONSTRAINT `community_comment_author_id_51c65c2a_fk_auth_user_id` FOREIGN KEY (`author_id`) REFERENCES `auth_user` (`id`),
  CONSTRAINT `community_comment_parent_comment_id_67b09268_fk_community` FOREIGN KEY (`parent_comment_id`) REFERENCES `community_comment` (`id`),
  CONSTRAINT `community_comment_post_id_12b521a8_fk_community_post_id` FOREIGN KEY (`post_id`) REFERENCES `community_post` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `community_comment`
--

LOCK TABLES `community_comment` WRITE;
/*!40000 ALTER TABLE `community_comment` DISABLE KEYS */;
/*!40000 ALTER TABLE `community_comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `community_post`
--

DROP TABLE IF EXISTS `community_post`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `community_post` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `board_type` varchar(10) NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` longtext NOT NULL,
  `image` varchar(100) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `view_count` int(11) NOT NULL,
  `author_id` int(11) NOT NULL,
  `like_count` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `community_post_author_id_a6c5f564_fk_auth_user_id` (`author_id`),
  CONSTRAINT `community_post_author_id_a6c5f564_fk_auth_user_id` FOREIGN KEY (`author_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `community_post`
--

LOCK TABLES `community_post` WRITE;
/*!40000 ALTER TABLE `community_post` DISABLE KEYS */;
INSERT INTO `community_post` VALUES
(1,'notice','공지 필독 바랍니다.','<p>환영합니다~</p>\r\n\r\n<p>규칙:</p>\r\n\r\n<p>1. 욕설 / 비방 금지</p>\r\n\r\n<p>2. 도용 / 불펌 금지</p>\r\n\r\n<p>위 두 사항이 적발될 경우 계정은&nbsp; 영구 정지 됩니다.</p>\r\n','community/케로케로_1.png','2026-07-16 02:23:34.698111',0,2,0),
(2,'notice','ㄴㅇㄹ','<p>ㄴㅇㄹㅇㄴㄹ</p>\r\n','','2026-07-16 02:23:56.358971',0,2,0),
(4,'notice','공지 필독 부탁드립니다.','<p>안녕하세요~ 환영합니다</p>\r\n\r\n<p>규칙</p>\r\n\r\n<p>1. 불펌 / 도용 금지</p>\r\n\r\n<p>2. 타인에 대한 욕설 및 비방 금지</p>\r\n\r\n<p>위 사항을 지키지 않을 시 경고조치 드립니다.</p>\r\n','community/케로케로.png','2026-07-16 02:34:25.052752',0,2,0),
(5,'qna','ㅇㄴㄴㅁ','<p>ㅇㄴㅁㄴㅇㅁ</p>\r\n','','2026-07-16 02:39:04.184597',3,2,0),
(6,'notice','ㅁㅇㄴㄹㅇ','<p>ㄹㅇㄴㅁㄹㅇㄴㄹ</p>\r\n','','2026-07-16 02:39:21.704053',0,2,0),
(7,'qna','ㅁㅇㄴㄹㄴㄻ','<p>ㄹㅇㄴㄹㅇㄴㄹ</p>\r\n','community/케로케로_mgjbD9W.png','2026-07-16 02:39:31.604432',3,2,0);
/*!40000 ALTER TABLE `community_post` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `community_post_likes`
--

DROP TABLE IF EXISTS `community_post_likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `community_post_likes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `post_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `community_post_likes_post_id_user_id_7155e6ea_uniq` (`post_id`,`user_id`),
  KEY `community_post_likes_user_id_88523dbc_fk_auth_user_id` (`user_id`),
  CONSTRAINT `community_post_likes_post_id_3dbbbf10_fk_community_post_id` FOREIGN KEY (`post_id`) REFERENCES `community_post` (`id`),
  CONSTRAINT `community_post_likes_user_id_88523dbc_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `community_post_likes`
--

LOCK TABLES `community_post_likes` WRITE;
/*!40000 ALTER TABLE `community_post_likes` DISABLE KEYS */;
/*!40000 ALTER TABLE `community_post_likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_chatroom`
--

DROP TABLE IF EXISTS `deal_chatroom`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_chatroom` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `buyer_id` int(11) NOT NULL,
  `goods_id` bigint(20) NOT NULL,
  `seller_id` int(11) NOT NULL,
  `buyer_last_viewed` datetime(6) NOT NULL,
  `seller_last_viewed` datetime(6) NOT NULL,
  `buyer_left` tinyint(1) NOT NULL,
  `seller_left` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deal_chatroom_goods_id_buyer_id_seller_id_2310ea4f_uniq` (`goods_id`,`buyer_id`,`seller_id`),
  KEY `deal_chatroom_buyer_id_05cd5aa4_fk_auth_user_id` (`buyer_id`),
  KEY `deal_chatroom_seller_id_94724b8b_fk_auth_user_id` (`seller_id`),
  CONSTRAINT `deal_chatroom_buyer_id_05cd5aa4_fk_auth_user_id` FOREIGN KEY (`buyer_id`) REFERENCES `auth_user` (`id`),
  CONSTRAINT `deal_chatroom_goods_id_a80f627e_fk_deal_goods_id` FOREIGN KEY (`goods_id`) REFERENCES `deal_goods` (`id`),
  CONSTRAINT `deal_chatroom_seller_id_94724b8b_fk_auth_user_id` FOREIGN KEY (`seller_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_chatroom`
--

LOCK TABLES `deal_chatroom` WRITE;
/*!40000 ALTER TABLE `deal_chatroom` DISABLE KEYS */;
INSERT INTO `deal_chatroom` VALUES
(2,'2026-07-13 06:05:54.884462',3,10,2,'2026-07-13 06:28:38.809304','2026-07-13 07:29:43.137545',0,0),
(3,'2026-07-13 06:12:49.914249',1,14,2,'2026-07-14 00:57:36.821354','2026-07-16 08:16:10.815011',0,0),
(4,'2026-07-13 06:25:53.267001',3,11,2,'2026-07-13 06:28:38.809304','2026-07-13 06:28:38.820228',0,0),
(5,'2026-07-13 07:04:37.121407',4,9,2,'2026-07-13 07:05:23.972205','2026-07-13 08:12:08.119835',1,0);
/*!40000 ALTER TABLE `deal_chatroom` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_goods`
--

DROP TABLE IF EXISTS `deal_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_goods` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `anime_title` varchar(100) NOT NULL,
  `category` varchar(20) NOT NULL,
  `price` int(11) NOT NULL,
  `status` varchar(10) NOT NULL,
  `shipping_methods` varchar(200) NOT NULL,
  `image` varchar(100) DEFAULT NULL,
  `description` longtext NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `seller_id` int(11) NOT NULL,
  `view_count` int(10) unsigned NOT NULL CHECK (`view_count` >= 0),
  PRIMARY KEY (`id`),
  KEY `deal_goods_seller_id_4d1b7456_fk_auth_user_id` (`seller_id`),
  CONSTRAINT `deal_goods_seller_id_4d1b7456_fk_auth_user_id` FOREIGN KEY (`seller_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_goods`
--

LOCK TABLES `deal_goods` WRITE;
/*!40000 ALTER TABLE `deal_goods` DISABLE KEYS */;
INSERT INTO `deal_goods` VALUES
(9,'프세카 피규어 팝니다!','프로세카, 프세카, 프로젝트세카이, 세카이','acrylic',23000,'sale','편의점 반택','goods_images/프세카피규어.png','하자는 없고 안전거래 합니다~\r\n원하는 캐릭터 말씀해주시면 유무 확인하고 알려드려요!','2026-07-10 09:47:19.455450',2,3),
(10,'앙스타 사쿠마레이 굿즈 3종','앙스타, 사쿠마, 사쿠마레이, 레이, 앙상블, 앙상블스타즈','etc',17000,'sale','준등기','goods_images/앙스타사쿠마레이.jpg','공굿 3종세트 일괄로 판매합니다.\r\n개별 판매는 안하고있어요\r\n택비포함','2026-07-13 03:00:35.869333',2,7),
(11,'귀칼 sd, ld 키링 판매','귀칼, 귀멸의칼날','acrylic',7000,'sold','택배','goods_images/귀칼키링.jpeg','개당 7000\r\n택비포함\r\n쿨거 환영합니다\r\n하자 없어용','2026-07-10 09:50:36.540493',2,15),
(12,'나눔해요','케로로','etc',0,'sale','반택','goods_images/타마마.jpeg','하자X','2026-07-13 05:26:23.655397',1,25),
(14,'기로로 피규어 판매함','기로로, 케로로','paper',19000,'sale','직거래','goods_images/기로로.jpeg','서울지역에서 직거래 가능합니다.\r\n노량진역 근처 희망합니다.','2026-07-10 10:34:23.254285',2,4);
/*!40000 ALTER TABLE `deal_goods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_goodsreport`
--

DROP TABLE IF EXISTS `deal_goodsreport`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_goodsreport` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `reason` varchar(20) NOT NULL,
  `detail` longtext NOT NULL,
  `status` varchar(10) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `goods_id` bigint(20) NOT NULL,
  `reporter_id` int(11) NOT NULL,
  `admin_note` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deal_goodsreport_reporter_id_goods_id_1bb34b96_uniq` (`reporter_id`,`goods_id`),
  KEY `deal_goodsreport_goods_id_e586d085_fk_deal_goods_id` (`goods_id`),
  CONSTRAINT `deal_goodsreport_goods_id_e586d085_fk_deal_goods_id` FOREIGN KEY (`goods_id`) REFERENCES `deal_goods` (`id`),
  CONSTRAINT `deal_goodsreport_reporter_id_c2ac74d5_fk_auth_user_id` FOREIGN KEY (`reporter_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_goodsreport`
--

LOCK TABLES `deal_goodsreport` WRITE;
/*!40000 ALTER TABLE `deal_goodsreport` DISABLE KEYS */;
/*!40000 ALTER TABLE `deal_goodsreport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_message`
--

DROP TABLE IF EXISTS `deal_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_message` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `content` longtext NOT NULL,
  `timestamp` datetime(6) NOT NULL,
  `room_id` bigint(20) NOT NULL,
  `sender_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `deal_message_room_id_f743ec59_fk_deal_chatroom_id` (`room_id`),
  KEY `deal_message_sender_id_853b28fb_fk_auth_user_id` (`sender_id`),
  CONSTRAINT `deal_message_room_id_f743ec59_fk_deal_chatroom_id` FOREIGN KEY (`room_id`) REFERENCES `deal_chatroom` (`id`),
  CONSTRAINT `deal_message_sender_id_853b28fb_fk_auth_user_id` FOREIGN KEY (`sender_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_message`
--

LOCK TABLES `deal_message` WRITE;
/*!40000 ALTER TABLE `deal_message` DISABLE KEYS */;
INSERT INTO `deal_message` VALUES
(2,'저기요','2026-07-13 06:22:14.999552',2,3),
(3,'왜요','2026-07-13 06:22:20.644971',2,2),
(4,'ㅋㅋㅋㅋ','2026-07-13 06:22:27.462470',2,2),
(5,'왜요 라뇨','2026-07-13 06:22:32.226161',2,3),
(6,'사실거에요? 사쿠마레이?','2026-07-13 06:22:39.250591',2,2),
(7,'사려고 연락한거에요','2026-07-13 06:22:39.398849',2,3),
(8,'저 지인 특별 할인가로','2026-07-13 06:22:50.770459',2,2),
(9,'살거니까 연락한거죠','2026-07-13 06:22:54.774026',2,3),
(10,'특별히 19000원에 드리려고하는데','2026-07-13 06:22:59.913515',2,2),
(11,'왜 더 비싸요','2026-07-13 06:23:20.822795',2,3),
(12,'ㅋㅋ','2026-07-13 06:23:23.454332',2,2),
(13,'신고할게요','2026-07-13 06:23:33.488213',2,3),
(14,'혼인신고 ,','2026-07-13 06:23:43.025568',2,3),
(15,'그러세요~ 제가 아직 신고하기 버튼을 안만들어서~','2026-07-13 06:23:45.108226',2,2),
(16,'아놔','2026-07-13 06:23:45.995778',2,2),
(17,'네','2026-07-13 06:23:46.931222',2,2),
(18,'당신은 이제 제껍니다.','2026-07-13 06:23:50.656119',2,3),
(19,'당황스럽네요, 좋습니다','2026-07-13 06:24:00.333875',2,2),
(32,'안녕하세요','2026-07-13 07:04:42.376228',5,4),
(33,'하이요','2026-07-13 07:04:46.291114',5,2),
(34,'어씨','2026-07-13 07:04:47.974151',5,4),
(35,'요씽','2026-07-13 07:04:49.519274',5,4),
(36,'신기하지 ㅋㅋㅋㅋ','2026-07-13 07:04:50.652118',5,2),
(37,'지린다잉','2026-07-13 07:04:52.002317',5,4),
(38,'터ㅏㅊ','2026-07-13 07:04:59.520449',5,2),
(39,'ㅌ커챀ㅌ','2026-07-13 07:05:00.293157',5,2),
(40,'ㅋㅋㅋ','2026-07-13 07:05:03.049432',5,2),
(41,'홀리 씻','2026-07-13 07:05:03.442272',5,4),
(42,'지린다','2026-07-13 07:05:06.841139',5,2),
(43,'카톡 만들어ㅓ줘','2026-07-13 07:05:06.876692',5,4),
(44,'ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ','2026-07-13 07:05:09.472267',5,2),
(45,'카톡같은','2026-07-13 07:05:09.572867',5,4),
(46,'프로구르매','2026-07-13 07:05:11.868459',5,4),
(47,'좋은걸로다가','2026-07-13 07:05:14.288598',5,4),
(48,'프로구르매는 뭐얔ㅋ','2026-07-13 07:05:16.827578',5,2),
(49,'ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ','2026-07-13 07:05:20.927795',5,4),
(50,'ㅋㅋㅋㅋㅋㅋㅋㅋ','2026-07-13 07:05:23.339528',5,2),
(51,'쩐다','2026-07-13 07:05:23.970788',5,4),
(52,'안녕하세요! 혹시 구매 가능할까요?','2026-07-13 08:12:33.160887',3,1),
(53,'안전하게 입금해 드리겠습니다. 계좌번호 부탁드립니다!','2026-07-13 08:12:37.152829',3,1),
(54,'엥','2026-07-13 08:13:15.450046',3,2),
(55,'sp?','2026-07-13 08:13:23.228779',3,1),
(56,'흠..','2026-07-13 08:13:29.327931',3,2),
(57,'그','2026-07-13 08:13:37.708206',3,1),
(58,'서울시 동작구 동작대로 29길 91, 사당동 우성아파트 204동 1007호','2026-07-13 08:13:51.801214',3,1),
(59,'?','2026-07-13 08:14:02.483385',3,2),
(60,'KB국민은행 50740201090626','2026-07-13 08:14:15.760388',3,2),
(61,'엥','2026-07-13 08:17:55.230069',3,1),
(62,'서울시 동작구 동작대로 29길 91','2026-07-13 08:18:02.255571',3,1),
(63,'KB국민은행 50740201090626','2026-07-13 08:18:18.476407',3,2),
(64,'응 ㅏㄴ댛','2026-07-13 08:19:01.953027',3,2),
(65,'안해','2026-07-13 08:19:03.154906',3,2),
(66,'ㅋㅋㅇㅈ','2026-07-13 08:19:08.665914',3,1),
(67,'엥','2026-07-13 08:19:13.344986',3,1),
(68,'엥','2026-07-13 08:19:21.589068',3,2),
(69,'어?','2026-07-13 08:19:27.210030',3,1),
(70,'응','2026-07-13 08:19:31.255426',3,2),
(71,'안녕하세요! 혹시 구매 가능할까요?','2026-07-13 08:22:29.880365',3,1),
(72,'배송비가 포함된 가격인가요?','2026-07-13 08:22:33.336484',3,1),
(73,'아','2026-07-13 08:23:00.142823',3,1),
(74,'아','2026-07-13 08:23:05.392321',3,1),
(75,'흠','2026-07-13 08:23:11.891976',3,1),
(76,'어','2026-07-13 08:23:36.730268',3,2),
(77,'응','2026-07-13 08:25:11.731080',3,2),
(78,'아','2026-07-13 08:26:44.500513',3,1),
(79,'됐네','2026-07-13 08:26:46.491493',3,1),
(80,'됐네요','2026-07-13 08:26:47.895183',3,1),
(81,'아','2026-07-13 08:27:09.990973',3,2),
(82,'KB국민은행 50740201090626','2026-07-13 08:27:21.335423',3,2),
(83,'엥','2026-07-13 08:27:39.067779',3,1),
(84,'또야?','2026-07-13 08:27:42.005505',3,1),
(85,'ㅇ','2026-07-13 08:29:23.290537',3,1),
(86,'어','2026-07-13 08:31:44.922145',3,1),
(87,'됐나','2026-07-13 08:31:45.892500',3,1),
(88,'됐나','2026-07-13 08:31:57.173342',3,2),
(89,'ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ','2026-07-13 08:32:06.670587',3,1),
(90,'유후','2026-07-13 08:32:12.062130',3,2),
(91,'ㅇㅇ','2026-07-13 08:33:44.306506',3,1),
(92,'ㅇㅇ','2026-07-13 08:33:46.063636',3,1),
(93,'ㅇㅇ','2026-07-13 08:33:46.713242',3,1),
(94,'난데','2026-07-13 08:33:48.753426',3,1),
(95,'이제','2026-07-13 08:37:32.770969',3,2),
(96,'아씨발','2026-07-13 08:37:36.128843',3,2),
(97,'되나?','2026-07-13 08:37:41.055501',3,2),
(98,'안되네','2026-07-13 08:37:44.170199',3,2),
(99,'ㅈ','2026-07-13 08:39:24.767245',3,1),
(100,'.','2026-07-13 08:39:31.970704',3,1),
(101,'ㅇ','2026-07-13 09:02:38.017225',3,2),
(102,'오','2026-07-13 09:02:42.754386',3,2),
(103,'오 됐네','2026-07-13 09:02:49.375498',3,1),
(104,'그아니','2026-07-13 09:02:51.633892',3,1),
(105,'됐나','2026-07-13 09:02:55.740566',3,1),
(106,'ㅋㅋㅋ','2026-07-13 09:02:56.955579',3,1),
(107,'오케이~','2026-07-13 09:02:58.431967',3,1);
/*!40000 ALTER TABLE `deal_message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_userreport`
--

DROP TABLE IF EXISTS `deal_userreport`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_userreport` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `reason` varchar(20) NOT NULL,
  `detail` longtext NOT NULL,
  `status` varchar(10) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `reported_user_id` int(11) NOT NULL,
  `reporter_id` int(11) NOT NULL,
  `admin_note` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deal_userreport_reporter_id_reported_user_id_80d7b7c9_uniq` (`reporter_id`,`reported_user_id`),
  KEY `deal_userreport_reported_user_id_7ad822fa_fk_auth_user_id` (`reported_user_id`),
  CONSTRAINT `deal_userreport_reported_user_id_7ad822fa_fk_auth_user_id` FOREIGN KEY (`reported_user_id`) REFERENCES `auth_user` (`id`),
  CONSTRAINT `deal_userreport_reporter_id_7ebacbb1_fk_auth_user_id` FOREIGN KEY (`reporter_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_userreport`
--

LOCK TABLES `deal_userreport` WRITE;
/*!40000 ALTER TABLE `deal_userreport` DISABLE KEYS */;
INSERT INTO `deal_userreport` VALUES
(3,'noshow','노쇼했어요 ㅁㅊ놈이','rejected','2026-07-16 08:37:33.084297',1,2,'관리자를 신고하셨습니다.');
/*!40000 ALTER TABLE `deal_userreport` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_wishlist`
--

DROP TABLE IF EXISTS `deal_wishlist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_wishlist` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `goods_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deal_wishlist_user_id_goods_id_954b86ab_uniq` (`user_id`,`goods_id`),
  KEY `deal_wishlist_goods_id_c4b98ac4_fk_deal_goods_id` (`goods_id`),
  CONSTRAINT `deal_wishlist_goods_id_c4b98ac4_fk_deal_goods_id` FOREIGN KEY (`goods_id`) REFERENCES `deal_goods` (`id`),
  CONSTRAINT `deal_wishlist_user_id_110ce785_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_wishlist`
--

LOCK TABLES `deal_wishlist` WRITE;
/*!40000 ALTER TABLE `deal_wishlist` DISABLE KEYS */;
INSERT INTO `deal_wishlist` VALUES
(7,'2026-07-14 05:44:26.717217',12,2),
(8,'2026-07-16 07:24:18.501134',14,2);
/*!40000 ALTER TABLE `deal_wishlist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_admin_log`
--

DROP TABLE IF EXISTS `django_admin_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_admin_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext DEFAULT NULL,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint(5) unsigned NOT NULL CHECK (`action_flag` >= 0),
  `change_message` longtext NOT NULL,
  `content_type_id` int(11) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `django_admin_log_content_type_id_c4bce8eb_fk_django_co` (`content_type_id`),
  KEY `django_admin_log_user_id_c564eba6_fk_auth_user_id` (`user_id`),
  CONSTRAINT `django_admin_log_content_type_id_c4bce8eb_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`),
  CONSTRAINT `django_admin_log_user_id_c564eba6_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_admin_log`
--

LOCK TABLES `django_admin_log` WRITE;
/*!40000 ALTER TABLE `django_admin_log` DISABLE KEYS */;
INSERT INTO `django_admin_log` VALUES
(1,'2026-07-10 08:46:59.324353','4','[판매중] 앙스타 사쿠마레이 굿즈 3종판매 - 20000원',3,'',7,2),
(2,'2026-07-10 08:46:59.324391','3','[판매중] 귀칼 키링판매 - 11500원',3,'',7,2),
(3,'2026-07-10 09:42:42.838191','7','[판매중] 아 팔아요 - 31123원',3,'',7,2),
(4,'2026-07-10 09:42:42.838226','6','[판매중] 앙 - 3243214원',3,'',7,2),
(5,'2026-07-10 09:43:24.986314','8','[판매중] ㅍ - 3412321원',3,'',7,2),
(6,'2026-07-10 09:43:24.986336','5','[판매중] 귀멸의칼날 키링판매 합니다. - 11500원',3,'',7,2),
(7,'2026-07-10 09:43:24.986346','2','[판매중] 프세카 피규어 팝니다! - 16000원',3,'',7,2),
(8,'2026-07-10 09:43:24.986355','1','[판매중] 이거 여기서 나눔 되나요? - 0원',3,'',7,2);
/*!40000 ALTER TABLE `django_admin_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_content_type`
--

DROP TABLE IF EXISTS `django_content_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_content_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_content_type`
--

LOCK TABLES `django_content_type` WRITE;
/*!40000 ALTER TABLE `django_content_type` DISABLE KEYS */;
INSERT INTO `django_content_type` VALUES
(1,'admin','logentry'),
(8,'anime','anime'),
(18,'anime','review'),
(2,'auth','group'),
(3,'auth','permission'),
(4,'auth','user'),
(9,'community','comment'),
(10,'community','post'),
(5,'contenttypes','contenttype'),
(11,'deal','chatroom'),
(7,'deal','goods'),
(16,'deal','goodsreport'),
(12,'deal','message'),
(17,'deal','userreport'),
(13,'deal','wishlist'),
(6,'sessions','session'),
(14,'works','creativework'),
(15,'works','workimage');
/*!40000 ALTER TABLE `django_content_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_migrations`
--

DROP TABLE IF EXISTS `django_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_migrations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES
(1,'contenttypes','0001_initial','2026-07-10 07:32:20.317612'),
(2,'auth','0001_initial','2026-07-10 07:32:20.371623'),
(3,'admin','0001_initial','2026-07-10 07:32:20.385248'),
(4,'admin','0002_logentry_remove_auto_add','2026-07-10 07:32:20.388958'),
(5,'admin','0003_logentry_add_action_flag_choices','2026-07-10 07:32:20.400728'),
(6,'contenttypes','0002_remove_content_type_name','2026-07-10 07:32:20.413776'),
(7,'auth','0002_alter_permission_name_max_length','2026-07-10 07:32:20.420849'),
(8,'auth','0003_alter_user_email_max_length','2026-07-10 07:32:20.425915'),
(9,'auth','0004_alter_user_username_opts','2026-07-10 07:32:20.428823'),
(10,'auth','0005_alter_user_last_login_null','2026-07-10 07:32:20.434821'),
(11,'auth','0006_require_contenttypes_0002','2026-07-10 07:32:20.435215'),
(12,'auth','0007_alter_validators_add_error_messages','2026-07-10 07:32:20.438141'),
(13,'auth','0008_alter_user_username_max_length','2026-07-10 07:32:20.445839'),
(14,'auth','0009_alter_user_last_name_max_length','2026-07-10 07:32:20.450531'),
(15,'auth','0010_alter_group_name_max_length','2026-07-10 07:32:20.455303'),
(16,'auth','0011_update_proxy_permissions','2026-07-10 07:32:20.458328'),
(17,'auth','0012_alter_user_first_name_max_length','2026-07-10 07:32:20.462932'),
(18,'deal','0001_initial','2026-07-10 07:32:20.471237'),
(19,'sessions','0001_initial','2026-07-10 07:32:20.477072'),
(20,'deal','0002_alter_goods_image','2026-07-10 09:38:06.108414'),
(21,'anime','0001_initial','2026-07-13 01:40:50.409609'),
(22,'community','0001_initial','2026-07-13 01:40:50.433710'),
(23,'deal','0003_chatroom_message','2026-07-13 03:47:50.799015'),
(24,'deal','0004_chatroom_buyer_last_viewed_and_more','2026-07-13 06:28:38.825245'),
(25,'deal','0005_chatroom_buyer_left_chatroom_seller_left','2026-07-13 06:59:17.506945'),
(26,'deal','0006_wishlist','2026-07-14 04:11:03.887377'),
(27,'deal','0007_goods_view_count','2026-07-14 04:43:47.148964'),
(28,'works','0001_initial','2026-07-15 08:16:29.866490'),
(29,'works','0002_workimage','2026-07-15 08:16:29.881616'),
(30,'community','0002_alter_post_board_type','2026-07-16 01:31:18.241602'),
(31,'community','0003_alter_post_content','2026-07-16 01:31:18.249169'),
(32,'community','0004_remove_post_like_count_post_likes','2026-07-16 01:31:18.283073'),
(33,'deal','0008_goodsreport_userreport','2026-07-16 07:59:29.913973'),
(34,'works','0003_creativework_status','2026-07-16 09:10:36.464833'),
(35,'works','0004_creativework_is_public','2026-07-16 09:10:36.479688'),
(36,'community','0005_alter_comment_options_comment_parent_comment_and_more','2026-07-16 09:23:01.720253'),
(37,'deal','0009_goodsreport_admin_note_userreport_admin_note','2026-07-20 02:17:09.950324'),
(38,'anime','0002_anime_backdrop_url_anime_first_air_date_and_more','2026-07-20 03:38:53.764317'),
(39,'anime','0003_review','2026-07-20 03:38:53.771871');
/*!40000 ALTER TABLE `django_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_session`
--

DROP TABLE IF EXISTS `django_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_expire_date_a5c62663` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_session`
--

LOCK TABLES `django_session` WRITE;
/*!40000 ALTER TABLE `django_session` DISABLE KEYS */;
INSERT INTO `django_session` VALUES
('1np1fq8o9o8oj799gs5tv5wpwj9w9f8a','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjpzh:ddF1LxXPf3HCn0zig_anC-U-Qg40IH4N2znDiES4Uhs','2026-07-29 03:09:09.081619'),
('243smitl8z5pv8hcotq6lifoke4ttltn','.eJxVjMEOwiAQRP-FsyGUdQt49O43kIUFqRpISnsy_rtt0oMeZ96beQtP61L82tPsJxYX4cTptwsUn6nugB9U703GVpd5CnJX5EG7vDVOr-vh_h0U6mVbA2ZFYQA6KzDZMCBxQtyyBgU6c2Y9Rjtay2CMsmjBDRgdRjSUDYrPF9UnNyQ:1wkHZ1:5SK-Zv43v98TCvOJvEmIvW9ySmpDoAocffbne4c3dWA','2026-07-30 08:35:27.408747'),
('4tv2yxwqzqqk5nwdg7zv5bwwounv36zo','.eJxVjMEOwiAQBf-FsyFQWAoevfcbCOyCVA0kpT0Z_9026UGvb2bem_mwrcVvPS1-JnZlml1-txjwmeoB6BHqvXFsdV3myA-Fn7TzqVF63U7376CEXvZaOHIOIygjXRxyBjKApAxJkhDGbJSxGTEq1Mntih2F0hoECJs0Dcg-X-dRN7Q:1wjAi4:Z2uwKHQnqB0yMrtQUA-67i6Q38Cyc2MM0Cp5rcuZjV4','2026-07-27 07:04:12.677956'),
('667kyvn80fm493jx97hfysmw1hxms0av','.eJxVjEEOwiAQRe_C2hBgHCwu3fcMZIBBqgaS0q6Md7dNutDte-__t_C0LsWvnWc_JXEVWonTLwwUn1x3kx5U703GVpd5CnJP5GG7HFvi1-1o_w4K9bKto8Wgc3DGaQfGIJtoiC2yggxDQMSImlJWCZgGBRewG0Frzww5cxCfL_smOAA:1wkHZ1:T3n0BW31NO0WXUnFipFwlI0weTtLa8ENxyR55EGZllo','2026-07-30 08:35:27.643760'),
('6q4ha5hkhqfgjgad1ef4m1e5ttl59lix','.eJxVjMsOwiAQRf-FtSHyZly69xvIwIBUDSSlXRn_3TbpQrf3nHveLOC61LCOPIeJ2IUpdvrdIqZnbjugB7Z756m3ZZ4i3xV-0MFvnfLrerh_gYqjbu-oEQqAQqMkClfAaheNzBSV9V5hIueIoijCoc06Fb-1pfcGALLUZ_b5Au6wOCE:1wj9nW:qkRfaB9GEzATJy_amXQPANt1s022rHCbcZaJQC7Q4eU','2026-07-27 06:05:46.590493'),
('8i9ni4b9zye3zhhch3pn2vd7zfued8lj','.eJxVjDsOwjAQRO_iGln-YbyU9DmDteu1cQA5UpxUiLuTSCmgnHlv5i0irkuNa89zHFlchTbi9FsSpmduO-EHtvsk09SWeSS5K_KgXQ4T59ftcP8OKva6rUMgQtS6GKu9cQAMyl5QWa_RFOdC9iFz2ZILmhKdyXpg5xMbgKyc-HwB83I3pQ:1wldS8:ICJXsBP69rsWvph8Mj0QkLJ8IQbnYNyuu4PTO-26y0U','2026-08-03 02:09:56.936307'),
('92ikun6nqs8cb3i3jptkbehycr9z4eyb','.eJxVjEEOwiAQRe_C2hCGUgGX7nsGMsOAVA1NSrsy3l1JutDNX_z38l4i4L6VsLe0hpnFRWhx-v0I4yPVDviO9bbIuNRtnUl2RR60yWnh9Lwe7l-gYCs9awZCjwTuOxk8jloNbJQaYGRDZ2I2bMFQJJu1gcjJUWYP2UZHEMX7A-z4OKg:1wldV9:y-XmdLtlqN_Tnk1ONOPuMCQA3AyI_uP0oq7IfPsnXkM','2026-08-03 02:13:03.322590'),
('b8l36icq8vpieuiepikuuv8zvz5jzen4','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjq6g:ZajliMkspfIjWXAS0o1hLaYtWFbaGjVAhAtrPxaZJfc','2026-07-29 03:16:22.094568'),
('cfz1v52ugybv4psx6lu6dmofeqeknkm9','.eJxVjEEOwiAQRe_C2hBgilCX7j0DGWZAqgaS0q6Md7dNutDte-__twi4LiWsPc1hYnERVpx-WUR6proLfmC9N0mtLvMU5Z7Iw3Z5a5xe16P9OyjYy7YmdDFbR37wo7LEmDUZ7VgPYJQ5j04Zj6BRReUceLYGgFlrCxtHyOLzBdLQNvo:1wkBuH:lWR65tuZJr1ZkdkTM_c_jRnTm5rYgLzdRu7PxOzeGdw','2026-07-30 02:33:01.472038'),
('cv2whldxwseukybit47dg8qbhmg1efff','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjUzo:UxaNZKr_DHCKcJ-qk2j16t6mprJBUzAZy_5E8wlJii0','2026-07-28 04:43:52.387213'),
('d3s1vsnkdwq6kgvvxdj21kmtmpbo82wz','.eJxVjEsOwjAMBe-SNYpaW_mYJXvOUDm1QwsokZp2hbg7VOoCtm9m3ssMvK3TsDVdhlnM2QRz-t0Sjw8tO5A7l1u1Yy3rMie7K_agzV6r6PNyuH8HE7fpW4Mm7gkkCPiOu-gxjw4xBnWpIwABJAWHmnufnTJJDkkJGDBjVDLvD92GN-M:1wkH5k:MzaIsGHPNjykU9t3-8xEBmJ-VdN5e30dPAkqGaLk_Xs','2026-07-30 08:05:12.431161'),
('e22qeaaum79uuoirg5f1gc9k4fuw96b6','.eJxVjMsOwiAQRf-FtSG8R1y67zeQAQapGkhKuzL-uzbpQrf3nHNfLOC21rANWsKc2YVJx06_Y8T0oLaTfMd26zz1ti5z5LvCDzr41DM9r4f7d1Bx1G9NxqMEa7JzCQo6bRBMlhFEsRbVWQiy5JUHD1amZISTpKMCjyLp4iN7fwD0vDd_:1wldnC:OqVC5s1xj2_MORqDfRoYvl-wGqB85V-xGEcS6XAbnwg','2026-08-03 02:31:42.109532'),
('eakv16o3zqa2vycngjrnd20lq27byouh','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjV28:7h19NWa5bDYVM0hH9SF8gh5yjXXV2YmqRVL_9_WNUrE','2026-07-28 04:46:16.038430'),
('g784tskwfkcorfpqrk3kitzsc9y26arl','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjUWp:fn2eLYpCP1gwnDl6Yd7nRfYVs67hNICsGQypm8F3mgU','2026-07-28 04:13:55.440191'),
('h5fxo27vo4r9mmd7t90ixjfusnho6tb8','.eJxVjEEOwiAQRe_C2hBgilCX7j0DGWZAqgaS0q6Md7dNutDte-__twi4LiWsPc1hYnERVpx-WUR6proLfmC9N0mtLvMU5Z7Iw3Z5a5xe16P9OyjYy7YmdDFbR37wo7LEmDUZ7VgPYJQ5j04Zj6BRReUceLYGgFlrCxtHyOLzBdLQNvo:1wkBu7:kdCYPZpSI6JX4qktsRhB4c4onQusRpFyy8RBhCqeuNw','2026-07-30 02:32:51.791101'),
('jbo6zchlaq3xtmrey9g29756hh2afzm3','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjAYO:69PcXWyT-bTORU8SnJVu2pH4yp2NWHsMttypQuV1_6E','2026-07-27 06:54:12.195293'),
('nekpsx9e53f7r5y26j69eqm9ehnbhdat','.eJxVjEEOwiAQRe_C2hCGUgGX7nsGMsOAVA1NSrsy3l1JutDNX_z38l4i4L6VsLe0hpnFRWhx-v0I4yPVDviO9bbIuNRtnUl2RR60yWnh9Lwe7l-gYCs9awZCjwTuOxk8jloNbJQaYGRDZ2I2bMFQJJu1gcjJUWYP2UZHEMX7A-z4OKg:1wjulU:Ay6TmYLjX5TFmGafHaN4dy47qAw0eVBrUrkxMoIVbn4','2026-07-29 08:14:48.604357'),
('q18zqmyzq7efbfdxb6glesq6a03andzj','.eJxVjDsOwjAQBe_iGlnxbx1T0nMGa9dr4wBypDipEHeHSCmgfTPzXiLitta49bzEicVZKCdOvyNheuS2E75ju80yzW1dJpK7Ig_a5XXm_Lwc7t9BxV6_tfGe2RAQJ2eCNjlYdL4QjBZZe8cFR60YtEqgi0UbgELmwQHwoAHE-wMO-zfk:1wldnC:TCCfxTEzPl4dMY7FLf2h7QLJMXjRK_xm53pVw9Uc0zk','2026-08-03 02:31:42.310319'),
('qvzew20gfm5bykaqzhvaapmrwwvvtbhu','.eJxVjEEOwiAQRe_C2hCGUgGX7nsGMsOAVA1NSrsy3l1JutDNX_z38l4i4L6VsLe0hpnFRWhx-v0I4yPVDviO9bbIuNRtnUl2RR60yWnh9Lwe7l-gYCs9awZCjwTuOxk8jloNbJQaYGRDZ2I2bMFQJJu1gcjJUWYP2UZHEMX7A-z4OKg:1wjTpa:nynXNRPAT0wsfwLcKxLajjUnCTEFX4sFxF7HpwmLIa4','2026-07-28 03:29:14.874917'),
('r1vq8oiry3o0kk84cfbizk15p4zkyk9p','.eJxVjDEOwyAQBP9CHSHAYCBler8Bwd0RnERYMnYV5e_Bkouk2WJndt8sxH0rYW-0hhnZlUnPLr9livCkehB8xHpfOCx1W-fED4WftPFpQXrdTvfvoMRW-lqYKC0myKB7YnRap9GiHAUZUuQ8OC0NEHmhACEbazQKlYchdQaafb41Zjj6:1wldrS:HNYP0vpf0l7m1VuNbD9OCK1VsI8qwEmuodHY-TCF2po','2026-08-03 02:36:06.518100'),
('tx1txwiu89qm9lx21fomigcx4049iemc','.eJxVjM0OwiAQhN-FsyFdfrbo0bvPQBZYpGogKe3J-O62SQ-auc33zbyFp3Upfu08-ymJi0Bx-u0CxSfXHaQH1XuTsdVlnoLcFXnQLm8t8et6uH8HhXrZ1sTBaWdDNAiaAIdzZiAyYJR2iASKVLKcnaJsByTDI0YzJrBbFLD4fAHdvzdb:1wkH5k:346wtKKSsLa18P_HbRdc6zit5UyH5-scmR0iN5yq2P4','2026-07-30 08:05:12.669763'),
('ua3q5auq55wipgsfzmv56dtnj6rflua9','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjuuN:T_domfyKZHgshhzU9778VA-T8J_25l9ISAMBduXYuJ4','2026-07-29 08:23:59.510111'),
('uonchchusf09xt4kpqc1tlztnhd6bafj','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wkHbe:Al5w9i5s6ajgxc5-Nl8J6d06f5xbgNxFD2U8ZTAvNyI','2026-07-30 08:38:10.139597'),
('upi486vzfarhs550simfy6kbae1znshg','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjUWg:XEKyKVgRVO8sDQBsolu2hQYvAkiD-wSV_LQmiKGQ0YA','2026-07-28 04:13:46.442870'),
('wo42xp69giblpqm8fbj84zmzfksmw5ob','.eJxVjDkOwjAUBe_iGlmxzbcTSvqcwfqbcQAlUpYKcXeIlALaNzPvZTJua83bonMexFyMM6ffjZAfOu5A7jjeJsvTuM4D2V2xB11sP4k-r4f7d1Bxqd-aO6GEZ2ZSBEqUXGAfEUrTRGw7USyqIMlHSJFdIQQIAoyldT5gMe8PHsE5SQ:1wjUZt:EAHPYwlSrTn5E12opfwwYJsB3HNZjHC_6JfLMbqwTyY','2026-07-28 04:17:05.544090'),
('yd78qx5q7srs4elv0xlgkv0h15gz8gp1','.eJxVjEEOgjAQRe_StWmADrTj0r1nIDOdjkVNSSisjHdXEha6_e-9_zIjbWset5qWcRJzNq0zp9-RKT5S2YncqdxmG-eyLhPbXbEHrfY6S3peDvfvIFPN3xo994MAQgsCQAmGjmHAFjuPoQnqRPtOMaIoOMYATKmBIMqa1Hk07w_scDgH:1wldS9:-A9LIRAVwwAdZ8lbbdCzkEWEtOhDNwGP4k_l1y86qpg','2026-08-03 02:09:57.136628'),
('zir2irj2uufzingxg32bticd1jw759ci','.eJxVjEEOwiAQRe_C2hCGUgGX7nsGMsOAVA1NSrsy3l1JutDNX_z38l4i4L6VsLe0hpnFRWhx-v0I4yPVDviO9bbIuNRtnUl2RR60yWnh9Lwe7l-gYCs9awZCjwTuOxk8jloNbJQaYGRDZ2I2bMFQJJu1gcjJUWYP2UZHEMX7A-z4OKg:1wj9uZ:hxiRIH-OZw-Od0trW40ZuMqM4gG4ShstS0wvBSN_N3c','2026-07-27 06:13:03.264128');
/*!40000 ALTER TABLE `django_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `works_creativework`
--

DROP TABLE IF EXISTS `works_creativework`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `works_creativework` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `target_program` varchar(100) NOT NULL,
  `category` varchar(20) NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` longtext NOT NULL,
  `image` varchar(100) DEFAULT NULL,
  `views` int(10) unsigned NOT NULL CHECK (`views` >= 0),
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `author_id` int(11) NOT NULL,
  `status` varchar(10) NOT NULL,
  `is_public` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `works_creativework_author_id_c8db868d_fk_auth_user_id` (`author_id`),
  CONSTRAINT `works_creativework_author_id_c8db868d_fk_auth_user_id` FOREIGN KEY (`author_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `works_creativework`
--

LOCK TABLES `works_creativework` WRITE;
/*!40000 ALTER TABLE `works_creativework` DISABLE KEYS */;
INSERT INTO `works_creativework` VALUES
(1,'최애의 아이','illustration','아이 그렸서요','막 맘에 들진 않지만 ..\r\n3시간컷낸 그림(귀찮아서 채색안한건 안비밀 ㅋㅋ)','works_images/최애의아이.jpg',5,'2026-07-15 09:47:17.170380','2026-07-15 09:47:25.935438',1,'published',1);
/*!40000 ALTER TABLE `works_creativework` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `works_creativework_bookmarks`
--

DROP TABLE IF EXISTS `works_creativework_bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `works_creativework_bookmarks` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `creativework_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `works_creativework_bookm_creativework_id_user_id_4056ad1f_uniq` (`creativework_id`,`user_id`),
  KEY `works_creativework_bookmarks_user_id_6525f68a_fk_auth_user_id` (`user_id`),
  CONSTRAINT `works_creativework_b_creativework_id_bca698de_fk_works_cre` FOREIGN KEY (`creativework_id`) REFERENCES `works_creativework` (`id`),
  CONSTRAINT `works_creativework_bookmarks_user_id_6525f68a_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `works_creativework_bookmarks`
--

LOCK TABLES `works_creativework_bookmarks` WRITE;
/*!40000 ALTER TABLE `works_creativework_bookmarks` DISABLE KEYS */;
/*!40000 ALTER TABLE `works_creativework_bookmarks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `works_creativework_likes`
--

DROP TABLE IF EXISTS `works_creativework_likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `works_creativework_likes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `creativework_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `works_creativework_likes_creativework_id_user_id_3f6485d2_uniq` (`creativework_id`,`user_id`),
  KEY `works_creativework_likes_user_id_90a3fa49_fk_auth_user_id` (`user_id`),
  CONSTRAINT `works_creativework_l_creativework_id_c25e4742_fk_works_cre` FOREIGN KEY (`creativework_id`) REFERENCES `works_creativework` (`id`),
  CONSTRAINT `works_creativework_likes_user_id_90a3fa49_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `works_creativework_likes`
--

LOCK TABLES `works_creativework_likes` WRITE;
/*!40000 ALTER TABLE `works_creativework_likes` DISABLE KEYS */;
/*!40000 ALTER TABLE `works_creativework_likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `works_workimage`
--

DROP TABLE IF EXISTS `works_workimage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `works_workimage` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `image` varchar(100) NOT NULL,
  `uploaded_at` datetime(6) NOT NULL,
  `work_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `works_workimage_work_id_ab4fc00e_fk_works_creativework_id` (`work_id`),
  CONSTRAINT `works_workimage_work_id_ab4fc00e_fk_works_creativework_id` FOREIGN KEY (`work_id`) REFERENCES `works_creativework` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `works_workimage`
--

LOCK TABLES `works_workimage` WRITE;
/*!40000 ALTER TABLE `works_workimage` DISABLE KEYS */;
/*!40000 ALTER TABLE `works_workimage` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-20 15:17:42

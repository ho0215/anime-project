-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: mydb
-- ------------------------------------------------------
-- Server version	8.0.46-0ubuntu0.24.04.3

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `works_creativework`
--

LOCK TABLES `works_creativework` WRITE;
/*!40000 ALTER TABLE `works_creativework` DISABLE KEYS */;
INSERT INTO `works_creativework` (`id`, `target_program`, `category`, `title`, `content`, `image`, `views`, `created_at`, `updated_at`, `author_id`, `status`, `is_public`) VALUES (1,'원피스 ','cosplay','원피스 주인공 루피','저는 외국인 이에요.\r\n일본의 애니를 너무 좋아합니다. 코스프레를 해보았다. 빠져들 것입니다. \r\n루피의 복근에 많은 집중을 해봤다.','works_images/원피스_코스프레.jpg',37,'2026-07-13 01:38:24.109862','2026-07-20 01:49:15.269653',1,'published',0),(2,'원피스','illustration','원피스. 그려보았습니다 +조로','항상 동경하던 나의 조로.. 저의 손으로 그려봤음 ㅋㅋ','works_images/원피스_일러스트.jpeg',16,'2026-07-14 03:01:30.444637','2026-07-14 03:01:30.444650',1,'published',1),(3,'원피스','novel','안개섬의 여인','\r\n<안개섬의 여인>\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n*조로 × 상디 × 미스터리한 여인 — 오리지널 사이드 스토리*\r\n\r\n---\r\n\r\n## 1화. 안개 속의 검객\r\n\r\n그랜드라인 어딘가, 지도에도 제대로 표기되지 않은 작은 섬 하나가 있었다. 섬 전체가 회백색 안개로 뒤덮여 있어 뱃사람들 사이에서는 \"안개섬\"이라 불렸다. 물자 보급을 위해 잠시 정박한 밀짚모자 일당은, 각자 흩어져 마을을 둘러보기로 했다.\r\n\r\n조로는 늘 그렇듯 방향을 잃었다.\r\n\r\n\"…분명 항구 쪽으로 걸었는데.\"\r\n\r\n안개는 짙었고, 나무들은 하나같이 비슷하게 생겨 있었다. 몇 번째 갈림길인지도 모를 곳에서 조로는 걸음을 멈췄다. 발밑에서 부스럭거리는 소리가 들렸기 때문이다.\r\n\r\n수풀 사이로 누군가 쓰러져 있었다. 짙은 보라색 로브를 걸친 여인이었다. 얼굴 절반을 가리는 후드, 그 아래로 드러난 입술만이 핏기 없이 창백했다.\r\n\r\n\"어이, 괜찮아?\"\r\n\r\n조로가 다가가려는 순간, 여인의 손이 빠르게 움직여 그의 발목을 붙잡았다. 힘이 실린 손아귀였다. 쓰러져 있던 사람의 것이라고는 믿기지 않을 정도로.\r\n\r\n\"…쫓기고 있어요.\"\r\n\r\n여인이 낮게 속삭였다. 그리고 그 말이 끝나기도 전에, 안개 저편에서 발소리가 울려 퍼지기 시작했다. 여럿이었다.\r\n\r\n같은 시각, 마을 반대편 골목. 상디는 담배 연기를 길게 내뿜으며 낡은 식료품점 앞을 서성이고 있었다.\r\n\r\n\"이 섬, 뭔가 이상한데.\"\r\n\r\n지나가는 사람이 거의 없었다. 있다 해도 하나같이 고개를 숙인 채 종종걸음으로 사라졌다. 마치 누군가의 눈을 피하는 사람들처럼.\r\n\r\n그때 멀리서 조로 쪽 방향으로 짐승 우는 소리 같기도 하고 사람의 고함 같기도 한 소리가 울렸다. 상디의 눈썹이 꿈틀거렸다.\r\n\r\n\"저 멍청한 검사, 또 뭔 사고를 친 거야.\"\r\n\r\n그는 담배를 밟아 끄고 소리가 난 방향으로 몸을 돌렸다.\r\n\r\n---\r\n\r\n## 2화. 추적자들\r\n\r\n조로는 여인을 등 뒤에 두고 칼자루에 손을 얹었다. 안개 사이로 그림자들이 하나둘 모습을 드러냈다. 검은 로브를 걸친 자들이었다. 얼굴은 보이지 않았지만, 걸음걸이에서 훈련받은 자들 특유의 절도가 느껴졌다.\r\n\r\n\"이 여자, 넘겨라.\"\r\n\r\n선두에 선 자가 낮게 말했다.\r\n\r\n조로는 대답 대신 칼을 뽑았다. 삼도류의 자세가 안개 속에서도 흔들림 없이 잡혔다.\r\n\r\n\"싫다면?\"\r\n\r\n말이 끝나자마자 그림자들이 일제히 달려들었다. 조로는 최소한의 움직임으로 첫 번째 상대의 무기를 튕겨내고, 두 번째 상대의 옆구리를 베었다. 하지만 숫자가 문제였다. 안개 속에서 몇 명이 더 튀어나올지 가늠이 되지 않았다.\r\n\r\n\"셋이서 붙는 건 좀 비겁하지 않아?\"\r\n\r\n익숙한 목소리와 함께, 다리 하나가 그림자의 얼굴을 걷어찼다. 상디였다.\r\n\r\n\"늦었잖아.\"\r\n\r\n\"길을 못 찾은 건 너였을 텐데.\"\r\n\r\n두 사람은 등을 맞대고 섰다. 손발이 맞지 않는 듯하면서도, 이상하리만치 서로의 빈틈을 메워가며 그림자들을 하나둘 쓰러뜨렸다.\r\n\r\n여인은 그 광경을 조용히 지켜보고 있었다. 후드 아래, 그녀의 눈동자가 미세하게 흔들렸다.\r\n\r\n마지막 그림자가 쓰러지자, 정적이 찾아왔다. 조로가 칼을 거두며 여인을 돌아봤다.\r\n\r\n\"이제 말해봐. 넌 누구고, 저것들은 뭐야.\"\r\n\r\n여인은 잠시 침묵하다가, 천천히 후드를 벗었다. 은빛에 가까운 백발, 그리고 왼쪽 눈가에 새겨진 낯선 문양 하나.\r\n\r\n\"제 이름은… 지금은 말씀드릴 수 없어요. 하지만 저들은 이 섬의 \'기억\'을 지키는 자들이에요. 그리고 저는, 그 기억에서 도망친 사람이고요.\"\r\n\r\n상디가 담배에 불을 붙이며 여인을 바라봤다.\r\n\r\n\"기억이라니. 무슨 말인지 하나도 모르겠는데.\"\r\n\r\n\"아가씨, 자세히 설명해 줄 수 있어?\"\r\n\r\n여인은 고개를 저었다.\r\n\r\n\"지금은 시간이 없어요. 저들 뒤에는… 더 큰 존재가 있어요. 곧 이 안개 자체가 움직일 거예요.\"\r\n\r\n그 말이 끝나기 무섭게, 발밑의 안개가 스스로 소용돌이치듯 일렁이기 시작했다.\r\n\r\n---\r\n\r\n## 3화. 안개가 걷힐 때\r\n\r\n땅이 미세하게 진동했다. 안개는 이제 단순한 기상현상이 아니라, 의지를 가진 것처럼 세 사람 주위를 휘감아 돌았다.\r\n\r\n\"이거… 누가 조종하고 있는 건가?\"\r\n\r\n조로가 검을 고쳐 쥐며 중얼거렸다.\r\n\r\n여인이 품속에서 작은 나침반 모양의 유물을 꺼냈다. 바늘이 아닌, 희미하게 빛나는 문양이 표면에 떠올라 있었다.\r\n\r\n\"이 섬은 원래 지도에 없어요. 안개가 이 섬을 세상으로부터 숨겨온 거죠. 저는… 그 봉인의 일부였어요.\"\r\n\r\n\"봉인의 일부라니, 그게 무슨—\"\r\n\r\n상디의 말이 끝나기도 전에, 안개 중심에서 거대한 그림자가 서서히 형체를 갖추기 시작했다. 사람도 짐승도 아닌, 안개 그 자체로 이루어진 무언가였다.\r\n\r\n\"…저게 네가 말한 \'더 큰 존재\'야?\"\r\n\r\n여인이 고개를 끄덕였다.\r\n\r\n\"제가 봉인에서 벗어나면서, 안개의 균형이 깨졌어요. 원래대로라면 제가 다시 안으로 들어가야 해요. 그래야 이 섬도, 저기 있는 사람들도 안전해질 거예요.\"\r\n\r\n조로와 상디는 서로를 힐끗 쳐다봤다. 말하지 않아도 통하는 무언가가 있었다.\r\n\r\n\"그럼 방법은 하나네.\"\r\n\r\n상디가 담배 연기를 내뿜으며 앞으로 나섰다.\r\n\r\n\"저 안개 덩어리를 흩어놓으면 되는 거 아냐?\"\r\n\r\n\"단순하게 말하는군. 하지만—\" 조로가 씩 웃으며 검을 세 자루째 뽑아 들었다. \"나쁘지 않은 방법이야.\"\r\n\r\n두 사람은 동시에 안개의 그림자를 향해 달려들었다. 상디의 발차기가 안개의 몸통을 가르고, 조로의 검이 응축된 어둠을 베어냈다. 그림자는 비명 같은 소리를 내며 서서히 옅어지기 시작했다.\r\n\r\n그 틈을 놓치지 않고 여인이 유물을 높이 들어 올렸다.\r\n\r\n\"돌아가라. 나의 자리로.\"\r\n\r\n빛이 사방으로 퍼지며, 소용돌이치던 안개가 서서히 걷히기 시작했다. 마을 곳곳에 숨죽이고 있던 사람들이 하나둘 밖으로 나와 하늘을 올려다봤다. 몇 년 만에 처음 보는 맑은 하늘이었다.\r\n\r\n안개가 완전히 걷혔을 때, 여인의 모습도 함께 사라져 있었다. 남은 것은 그녀가 서 있던 자리에 놓인 작은 나침반뿐이었다.\r\n\r\n조로가 그것을 주워 들었다.\r\n\r\n\"…뭐였던 거야, 저 여자.\"\r\n\r\n상디는 대답 없이 담배 연기만 길게 내뿜었다. 안개가 사라진 하늘 위로, 두 개의 태양처럼 보이는 노을이 걸려 있었다.\r\n\r\n\"글쎄. 하지만 덕분에 이 섬 사람들은 오랜만에 하늘을 보네.\"\r\n\r\n두 사람은 나침반을 품에 넣고, 조용히 항구를 향해 걸음을 옮겼다. 동료들이 기다리고 있을 배를 향해서.\r\n\r\n**— 完 —**\r\n\r\n---\r\n\r\n*※ 이 이야기는 원작 스토리라인이나 특정 시점의 설정과 무관하게 진행되는 오리지널 사이드 에피소드입니다. 등장인물의 성격과 관계성은 원작을 기반으로 하되, 세계관 설정(지역명, 현상금, 최근 사건 등)과의 충돌을 피하기 위해 구체적인 시점은 의도적으로 특정하지 않았습니다.*\r\n','works_images/원피스_팬픽_안개섬의_여인_1.md',30,'2026-07-14 06:13:11.508834','2026-07-15 03:16:31.284936',1,'published',1),(4,'최애의 아이','illustration','최애의 아이 그려봣습니다','낙퀄로 그려왔습니다 (채색은 귀찮았던거 안비밀ㅋㅋ)\n좀 맘에 안들긴 한데.. 크흠','works_images/최애의아이.jpg',23,'2026-07-15 09:15:45.148545','2026-07-20 02:59:41.493192',2,'published',1),(8,'sdfgsdg','illustration','htgrh','teryhteetyhgetr','',1,'2026-07-20 01:50:29.399815','2026-07-20 01:50:29.399824',1,'draft',1),(10,'원작 따윈 없다 이것은 소설인가 뭐시긴가','novel','테스트 소설','안녕하세요 이것은 테스트 문장입니다.  여러분 모두 행복하세요\n이 글을 본 당신은 사랑받기 위해 태어난 사람입니다 모든게 억까 같고 힘드실테지만 우리 더 멋진 내일을 위해 하루 , 하루 더 버텨봅시다 . .','',26,'2026-07-20 03:12:34.104572','2026-07-20 03:24:04.996756',1,'published',1);
/*!40000 ALTER TABLE `works_creativework` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `works_creativework_bookmarks`
--

LOCK TABLES `works_creativework_bookmarks` WRITE;
/*!40000 ALTER TABLE `works_creativework_bookmarks` DISABLE KEYS */;
INSERT INTO `works_creativework_bookmarks` (`id`, `creativework_id`, `user_id`) VALUES (1,3,2),(3,4,1);
/*!40000 ALTER TABLE `works_creativework_bookmarks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `works_creativework_likes`
--

LOCK TABLES `works_creativework_likes` WRITE;
/*!40000 ALTER TABLE `works_creativework_likes` DISABLE KEYS */;
INSERT INTO `works_creativework_likes` (`id`, `creativework_id`, `user_id`) VALUES (3,1,2),(1,3,2),(4,4,1),(5,10,2);
/*!40000 ALTER TABLE `works_creativework_likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `works_workimage`
--

LOCK TABLES `works_workimage` WRITE;
/*!40000 ALTER TABLE `works_workimage` DISABLE KEYS */;
INSERT INTO `works_workimage` (`id`, `image`, `uploaded_at`, `work_id`) VALUES (1,'works_images/원피스_일러스트_조로.jpeg','2026-07-14 03:01:30.452710',2);
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

-- Dump completed on 2026-07-22 10:01:35

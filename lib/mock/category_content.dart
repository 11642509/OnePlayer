// 模拟分类内容数据
class CategoryContent {
  static Map<String, dynamic> getMockData(String typeId) {
    // 根据分类ID返回对应的数据
    switch (typeId) {
      case "0": // 主页
        return getHomeData();
      case "2": // 电视剧
        return getTVData();
      case "1": // 电影
        return getMovieData();
      case "6": // 综艺
        return getVarietyData();
      case "4": // 动漫
        return getAnimeData();
      case "15": // 儿童
        return getMusicData();
      default:
        return getHomeData();
    }
  }

  // 主页数据
  static Map<String, dynamic> getHomeData() {
    return {
      "code": 0,
      "msg": "",
      "page": 1,
      "pagecount": 1600,
      "limit": 10,
      "total": 16000,
      "list": [
        {
          "vod_id": "MTk3ODY0MjMzNDE5NTgwMXwyfOS4tOaxn+S7mXxodHRwOi8vcGljNS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDkvNjYvZjcvYV8xMDA1NzA2NzNfbV82MDFfbTkuanBn",
          "vod_name": "临江仙",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250609/66/f7/a_100570673_m_601_m9.jpg",
          "vod_remarks": "更新至 22集"
        },
        {
          "vod_id": "Njk4ODE2ODA1MzA4MjYwMXwyfOazlee9kee8ieWHtnxodHRwOi8vcGljOS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MTMvNTIvNzcvYV8xMDA2Mjk2ODVfbV82MDFfbTUuanBn",
          "vod_name": "法网缉凶",
          "vod_pic": "http://pic9.iqiyipic.com/image/20250613/52/77/a_100629685_m_601_m5.jpg",
          "vod_remarks": "更新至 26集"
        },
        {
          "vod_id": "NDkyMDE4NDQ5NzcxMTMwMXwyfOaKpOWuneWvu+i4qnxodHRwOi8vcGljMy5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjIvNTAvMmMvYV8xMDA1NjMyMDRfbV82MDFfbTEzLmpwZw==",
          "vod_name": "护宝寻踪",
          "vod_pic": "http://pic3.iqiyipic.com/image/20250522/50/2c/a_100563204_m_601_m13.jpg",
          "vod_remarks": "更新至 36集"
        },
        {
          "vod_id": "NTk2ODYxNTI2MDY1NjcwMXwyfOa2iOWkseeahOeIseS6unxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MzAvYWUvZGQvYV8xMDA2MjY4NzJfbV82MDFfbTMuanBn",
          "vod_name": "消失的爱人",
          "vod_pic": "http://pic4.iqiyipic.com/image/20250530/ae/dd/a_100626872_m_601_m3.jpg",
          "vod_remarks": "更新至 24集"
        },
        {
          "vod_id": "MTQ4NzcxNjgzNTQwNDEwMXwyfOS4jeivhuWQm3xodHRwOi8vcGljNi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDUvZDMvNDIvYV8xMDA2MjY4MjNfbV82MDFfbTMuanBn",
          "vod_name": "不识君",
          "vod_pic": "http://pic6.iqiyipic.com/image/20250605/d3/42/a_100626823_m_601_m3.jpg",
          "vod_remarks": "更新至 24集"
        }
      ]
    };
  }

  // 电视剧数据
  static Map<String, dynamic> getTVData() {
    return {
      "code": 0,
      "msg": "",
      "page": 1,
      "pagecount": 1600,
      "limit": 10,
      "total": 16000,
      "list": [
        {
          "vod_id": "MTk3ODY0MjMzNDE5NTgwMXwyfOS4tOaxn+S7mXxodHRwOi8vcGljNS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDkvNjYvZjcvYV8xMDA1NzA2NzNfbV82MDFfbTkuanBn",
          "vod_name": "临江仙",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250609/66/f7/a_100570673_m_601_m9.jpg",
          "vod_remarks": "更新至 22集"
        },
        {
          "vod_id": "Njk4ODE2ODA1MzA4MjYwMXwyfOazlee9kee8ieWHtnxodHRwOi8vcGljOS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MTMvNTIvNzcvYV8xMDA2Mjk2ODVfbV82MDFfbTUuanBn",
          "vod_name": "法网缉凶",
          "vod_pic": "http://pic9.iqiyipic.com/image/20250613/52/77/a_100629685_m_601_m5.jpg",
          "vod_remarks": "更新至 26集"
        },
        {
          "vod_id": "NDkyMDE4NDQ5NzcxMTMwMXwyfOaKpOWuneWvu+i4qnxodHRwOi8vcGljMy5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjIvNTAvMmMvYV8xMDA1NjMyMDRfbV82MDFfbTEzLmpwZw==",
          "vod_name": "护宝寻踪",
          "vod_pic": "http://pic3.iqiyipic.com/image/20250522/50/2c/a_100563204_m_601_m13.jpg",
          "vod_remarks": "更新至 36集"
        },
        {
          "vod_id": "NTk2ODYxNTI2MDY1NjcwMXwyfOa2iOWkseeahOeIseS6unxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MzAvYWUvZGQvYV8xMDA2MjY4NzJfbV82MDFfbTMuanBn",
          "vod_name": "消失的爱人",
          "vod_pic": "http://pic4.iqiyipic.com/image/20250530/ae/dd/a_100626872_m_601_m3.jpg",
          "vod_remarks": "更新至 24集"
        },
        {
          "vod_id": "MTQ4NzcxNjgzNTQwNDEwMXwyfOS4jeivhuWQm3xodHRwOi8vcGljNi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDUvZDMvNDIvYV8xMDA2MjY4MjNfbV82MDFfbTMuanBn",
          "vod_name": "不识君",
          "vod_pic": "http://pic6.iqiyipic.com/image/20250605/d3/42/a_100626823_m_601_m3.jpg",
          "vod_remarks": "更新至 24集"
        }
      ]
    };
  }

  // 电影数据
  static Map<String, dynamic> getMovieData() {
    return {
      "code": 0,
      "msg": "",
      "page": 1,
      "pagecount": 1600,
      "limit": 10,
      "total": 16000,
      "list": [
        {
          "vod_id": "MjgxNjEwMzQ4MTU5MjgwMHwxfOaJq+avkumjjuaatHxodHRwOi8vcGljNS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MTMvMjEvZDIvdl8xODE1OTg0MDJfbV82MDFfbTQuanBn",
          "vod_name": "扫毒风暴",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250613/21/d2/v_181598402_m_601_m4.jpg",
          "vod_remarks": "2025-05-31"
        },
        {
          "vod_id": "NTU4MDM2Njk5Mjc2ODcwMHwxfOS5neWPlOS5i+mSn+mml+W9kuadpXxodHRwOi8vcGljOS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDUvMjYvMDQvdl8xODE2ODQyNjBfbV82MDFfbTIuanBn",
          "vod_name": "九叔之钟馗归来",
          "vod_pic": "http://pic9.iqiyipic.com/image/20250605/26/04/v_181684260_m_601_m2.jpg",
          "vod_remarks": "2025-06-12"
        }
      ]
    };
  }

  // 综艺数据
  static Map<String, dynamic> getVarietyData() {
    return {
      "code": 0,
      "msg": "",
      "page": 1,
      "pagecount": 1600,
      "limit": 10,
      "total": 16000,
      "list": [
        {
          "vod_id": "NDIxNjY4NTA0OTI3ODkwMXw2fOWTiOWTiOWTiOWTiOWTiOesrDXlraN8aHR0cDovL3BpYzUuaXFpeWlwaWMuY29tL2ltYWdlLzIwMjUwNDEwLzMzL2JkL2FfMTAwNTk2MzcyX21fNjAxX202LmpwZw==",
          "vod_name": "哈哈哈哈哈第5季",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250410/33/bd/a_100596372_m_601_m6.jpg",
          "vod_remarks": "2025-06-14"
        },
        {
          "vod_id": "MjY1NzI3NDY0MTM1MDUwMXw2fOaWsOivtOWUsTIwMjV8aHR0cDovL3BpYzguaXFpeWlwaWMuY29tL2ltYWdlLzIwMjUwNjA2LzMwL2RhL2FfMTAwNTkwNjc4X21fNjAxX20xMC5qcGc=",
          "vod_name": "新说唱2025",
          "vod_pic": "http://pic8.iqiyipic.com/image/20250606/30/da/a_100590678_m_601_m10.jpg",
          "vod_remarks": "2025-06-14"
        },
        {
          "vod_id": "NTc4MjUxMjc4Mzk5MDQwMXw2fOenjeWcsOWQp+esrDPlraN8aHR0cDovL3BpYzUuaXFpeWlwaWMuY29tL2ltYWdlLzIwMjUwMjI4LzcxL2RkL2FfMTAwNTkwOTA1X21fNjAxX201LmpwZw==",
          "vod_name": "种地吧第3季",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250228/71/dd/a_100590905_m_601_m5.jpg",
          "vod_remarks": "2025-06-14"
        },
        {
          "vod_id": "MjI1Njk5Mzg4MzM0ODEwMXw2fHdlae+8geW/q+WHuuadpeeOqXxodHRwOi8vcGljMS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjkvMzcvMTgvYV8xMDA2MjMyOTBfbV82MDFfbTIuanBn",
          "vod_name": "wei!快出来玩",
          "vod_pic": "http://pic1.iqiyipic.com/image/20250529/37/18/a_100623290_m_601_m2.jpg",
          "vod_remarks": "2025-06-14"
        }
      ]
    };
  }

  // 动漫数据
  static Map<String, dynamic> getAnimeData() {
    return {
      "code": 0,
      "msg": "",
      "page": 1,
      "pagecount": 1600,
      "limit": 10,
      "total": 16000,
      "list": [
        {
          "vod_id": "ODI0MDM0ODk0MTM0MTMwMXw0fOS9meeDrOihjOiAhXxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjgvMzYvOGMvYV8xMDA1MzQ0NjdfbV82MDFfbTE0LmpwZw==",
          "vod_name": "余烬行者",
          "vod_pic": "http://pic4.iqiyipic.com/image/20250528/36/8c/a_100534467_m_601_m14.jpg",
          "vod_remarks": "更新至 3集"
        },
        {
          "vod_id": "MjMyNTExNjAxfDR85byA5b+D6ZSk6ZSkfGh0dHA6Ly9waWMzLmlxaXlpcGljLmNvbS9pbWFnZS8yMDI0MDYxMS82Ny8xMi9hXzEwMDIwODk1NF9tXzYwMV9tMjQuanBn",
          "vod_name": "开心锤锤",
          "vod_pic": "http://pic3.iqiyipic.com/image/20240611/67/12/a_100208954_m_601_m24.jpg",
          "vod_remarks": "更新至 564集"
        },
        {
          "vod_id": "NjIyNTMwODMzMTkxOTIwMXw0fOelnuWbveS5i+S4inxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA0MzAvZTUvYzkvYV8xMDA1NzE2MzVfbV82MDFfbTUuanBn",
          "vod_name": "神国之上",
          "vod_pic": "http://pic4.iqiyipic.com/image/20250430/e5/c9/a_100571635_m_601_m5.jpg",
          "vod_remarks": "更新至 3集"
        },
        {
          "vod_id": "NzY0NzU0ODM3OTg5MTkwMXw0fOS7meWuoHxodHRwOi8vcGljMS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDMvYTQvMGQvYV8xMDA1MzQ1OTBfbV82MDFfbTEwLmpwZw==",
          "vod_name": "仙宠",
          "vod_pic": "http://pic1.iqiyipic.com/image/20250603/a4/0d/a_100534590_m_601_m10.jpg",
          "vod_remarks": "更新至 3集"
        },
        {
          "vod_id": "NDYxNzc2Nzk3MzEzMDEwMXw0fOWQieS8iuWNoeWThyDnrKwx5a2jIOaZrumAmuivnXxodHRwOi8vcGljMi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTAzMTEvOTAvNTEvYV8xMDA2MDMzNThfbV82MDFfbTQuanBn",
          "vod_name": "吉伊卡哇 第1季 普通话",
          "vod_pic": "http://pic2.iqiyipic.com/image/20250311/90/51/a_100603358_m_601_m4.jpg",
          "vod_remarks": "更新至 120集"
        }
      ]
    };
  }

  // 音乐数据（用于儿童分类）
  static Map<String, dynamic> getMusicData() {
    return {
      "code": 0,
      "msg": "",
      "page": 1,
      "pagecount": 1600,
      "limit": 10,
      "total": 16000,
      "list": [
        {
          "vod_id": "MjQ0NDcwMDY5MTcwNzgwMXw1fOecn+aYr+mrmOaJi+WcqOawkemXtO+8jOi/meS6m+S6uuS4gOW8gOWPo+WwseaDiuiJs+S6hu+8jOWUseWKn+S4jei+k+S4k+S4muatjOaJi3xodHRwOi8vcGljMS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyMzA2MjkvMmIvZjUvYV8xMDA0Mjc0MzJfbV82MDFfbTEuanBn",
          "vod_name": "真是高手在民间,这些人一开口就惊艳了,唱功不输专业歌手",
          "vod_pic": "http://pic1.iqiyipic.com/image/20230629/2b/f5/a_100427432_m_601_m1.jpg",
          "vod_remarks": "更新至 0集"
        },
        {
          "vod_id": "MjI3NTM1MjAxfDV86Z+z5LmQRmFuc+Wwj+eQvHxodHRwOi8vcGljMC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyMzA2MjkvZTkvNzYvYV8xMDAxNjAwNjRfbV82MDFfbTEuanBn",
          "vod_name": "音乐fans小琼",
          "vod_pic": "http://pic0.iqiyipic.com/image/20230629/e9/76/a_100160064_m_601_m1.jpg",
          "vod_remarks": "更新至 0集"
        },
        {
          "vod_id": "MjI2MzQyNjAxfDV85Lmd5ZCs6Z+z5LmQ5Y6f5YibTVblkIjovpF8aHR0cDovL3BpYzMuaXFpeWlwaWMuY29tL2ltYWdlLzIwMjMwNjI5L2JlLzY0L2FfMTAwMTQ4Njc2X21fNjAxX20xOS5qcGc=",
          "vod_name": "九听音乐原创mv合辑",
          "vod_pic": "http://pic3.iqiyipic.com/image/20230629/be/64/a_100148676_m_601_m19.jpg",
          "vod_remarks": "更新至 0集"
        },
        {
          "vod_id": "MjQ5MzYzMTAxfDV854Ot6Zeo5rWB6KGM5q2M5puy5bm/5Zy66Iie77yM6IqC5aWP5Yqo5oSf77yM5aW95ZCs5pu05aW955yLfGh0dHA6Ly9waWM4LmlxaXlpcGljLmNvbS9pbWFnZS8yMDIwMTExNC80NS81Ny9hXzEwMDM3MzEyM19tXzYwMV9tMi5qcGc=",
          "vod_name": "热门流行歌曲广场舞,节奏动感,好听更好看",
          "vod_pic": "http://pic8.iqiyipic.com/image/20201114/45/57/a_100373123_m_601_m2.jpg",
          "vod_remarks": "更新至 0集"
        },
        {
          "vod_id": "Nzg4MDE3NjQ3NTcyNTEwMXw1fOe9kee7nOeDreatjOadpeiire+8jOeHleWtkOW4puaCqOi3s+i1t+adpXxodHRwOi8vcGljOC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNDA5MTEvZmYvODAvYV8xMDA1ODk0OTRfbV82MDEuanBn",
          "vod_name": "网络热歌来袭,燕子带您跳起来",
          "vod_pic": "http://pic8.iqiyipic.com/image/20240911/ff/80/a_100589494_m_601.jpg",
          "vod_remarks": "更新至 0集"
        },
        {
          "vod_id": "MjI3NDk4MjAxfDV85LiL6aWt6Z+z5LmQfGh0dHA6Ly9waWM3LmlxaXlpcGljLmNvbS9pbWFnZS8yMDIzMDYyOS9kZi9lNy9hXzEwMDE1OTY5NF9tXzYwMV9tNS5qcGc=",
          "vod_name": "下饭音乐",
          "vod_pic": "http://pic7.iqiyipic.com/image/20230629/df/e7/a_100159694_m_601_m5.jpg",
          "vod_remarks": "更新至 0集"
        },
        {
          "vod_id": "NTMzODkxNTA3MDIwOTUwMXw1fOWwj+WnkOWnkEJpZei3keeahOmfs+S5kOWQiOmbhu+8muWbveWGhee7vOiJuueahOWHuuWciOelnuabsu+8jOWkquacieail+S6hu+8gXxodHRwOi8vcGljNy5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyMzEwMTcvN2UvYTgvYV8xMDA0Mjg1MDFfbV82MDFfbTEuanBn",
          "vod_name": "小姐姐bie跑的音乐合集:国内综艺的出圈神曲,太有梗了!",
          "vod_pic": "http://pic7.iqiyipic.com/image/20231017/7e/a8/a_100428501_m_601_m1.jpg",
          "vod_remarks": "更新至 0集"
        }
      ]
    };
  }
} 
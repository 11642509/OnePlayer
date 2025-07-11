// 模拟首页数据
class HomeContent {
  static Map<String, dynamic> getMockData() {
    return {
      "code": 0,
      "msg": "",
      "class": [
        {"type_id": "2", "type_name": "电视剧"},
        {"type_id": "1", "type_name": "电影"},
        {"type_id": "6", "type_name": "综艺"},
        {"type_id": "4", "type_name": "动漫"},
        {"type_id": "15", "type_name": "儿童"}
      ],
      "filters": {
        "1": [
          {
            "key": "mode",
            "name": "排序",
            "value": [
              {"n": "综合排序", "v": "24"},
              {"n": "热播榜", "v": "11"},
              {"n": "好评榜", "v": "8"},
              {"n": "新上线", "v": "4"}
            ]
          },
          {
            "key": "market_release_date_level",
            "name": "年份",
            "value": [
              {"n": "全部年份", "v": ""},
              {"n": "2022", "v": "2022"},
              {"n": "2021", "v": "2021"},
              {"n": "2020", "v": "2020"},
              {"n": "2019", "v": "2019"},
              {"n": "2018", "v": "2018"},
              {"n": "2017", "v": "2017"},
              {"n": "2016-2011", "v": "2011_2016"},
              {"n": "2010-2000", "v": "2000_2010"},
              {"n": "90年代", "v": "1990_1999"},
              {"n": "80年代", "v": "1980_1989"},
              {"n": "更早", "v": "1964_1979"}
            ]
          },
          {
            "key": "three_category_id",
            "name": "地区",
            "value": [
              {"n": "全部地区", "v": ""},
              {"n": "华语", "v": "1"},
              {"n": "香港地区", "v": "28997"},
              {"n": "美国", "v": "2"},
              {"n": "欧洲", "v": "3"},
              {"n": "韩国", "v": "4"},
              {"n": "日本", "v": "308"},
              {"n": "泰国", "v": "1115"},
              {"n": "印度", "v": "28999"},
              {"n": "其它", "v": "5"}
            ]
          },
          {
            "key": "must0",
            "name": "类型",
            "value": [
              {"n": "全部类型", "v": ""},
              {"n": "喜剧", "v": "8"},
              {"n": "爱情", "v": "6"},
              {"n": "动作", "v": "11"},
              {"n": "枪战", "v": "131"},
              {"n": "犯罪", "v": "291"},
              {"n": "惊悚", "v": "128"},
              {"n": "恐怖", "v": "10"},
              {"n": "悬疑", "v": "289"},
              {"n": "动画", "v": "12"},
              {"n": "家庭", "v": "27356"},
              {"n": "奇幻", "v": "1284"},
              {"n": "魔幻", "v": "129"},
              {"n": "科幻", "v": "9"},
              {"n": "战争", "v": "7"},
              {"n": "青春", "v": "130"}
            ]
          }
        ],
        "15": [
          {
            "key": "mode",
            "name": "排序",
            "value": [
              {"n": "综合排序", "v": "24"},
              {"n": "热播榜", "v": "11"},
              {"n": "好评榜", "v": "8"},
              {"n": "新上线", "v": "4"}
            ]
          }
        ]
      },
      "list": [
        {
          "vod_id": "MTk3ODY0MjMzNDE5NTgwMXwyfOS4tOaxn+S7mXxodHRwOi8vcGljNS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDkvNjYvZjcvYV8xMDA1NzA2NzNfbV82MDFfbTkuanBn",
          "vod_name": "临江仙",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250609/66/f7/a_100570673_m_601_m9.jpg",
          "vod_remarks": "更新至20集"
        },
        {
          "vod_id": "NDkyMDE4NDQ5NzcxMTMwMXwyfOaKpOWuneWvu+i4qnxodHRwOi8vcGljMy5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjIvNTAvMmMvYV8xMDA1NjMyMDRfbV82MDFfbTEzLmpwZw==",
          "vod_name": "护宝寻踪",
          "vod_pic": "http://pic3.iqiyipic.com/image/20250522/50/2c/a_100563204_m_601_m13.jpg",
          "vod_remarks": "更新至36集"
        },
        {
          "vod_id": "NTUyNzQyNDA0NDQyMDMwMXwyfOaXoOW/p+a4oXxodHRwOi8vcGljMC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA0MjgvYjkvZDIvYV8xMDA1MTIyOThfbV82MDFfbTEzLmpwZw==",
          "vod_name": "无忧渡",
          "vod_pic": "http://pic0.iqiyipic.com/image/20250428/b9/d2/a_100512298_m_601_m13.jpg",
          "vod_remarks": "更新至36集"
        },
        {
          "vod_id": "MTQ4MjkwMzg0MDMxNjkwMXwyfOeZveaciOaiteaYn3xodHRwOi8vcGljMy5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTAxMDkvODAvZWYvYV8xMDA1NDU0MTFfbV82MDFfbTEyLmpwZw==",
          "vod_name": "白月梵星",
          "vod_pic": "http://pic3.iqiyipic.com/image/20250109/80/ef/a_100545411_m_601_m12.jpg",
          "vod_remarks": "更新至40集"
        },
        {
          "vod_id": "Mzc1NzA0NDAxODU0NTIwMXwyfOS6uueUn+iLpeWmguWIneingXxodHRwOi8vcGljOC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MTMvMmMvZWIvYV8xMDA0MzEyOTBfbV82MDFfbTEwLmpwZw==",
          "vod_name": "人生若如初见",
          "vod_pic": "http://pic8.iqiyipic.com/image/20250513/2c/eb/a_100431290_m_601_m10.jpg",
          "vod_remarks": "更新至40集"
        },
        {
          "vod_id": "NTU2NzUzMjMzNjgwNTIwMXwyfOa3ruawtOerueS6rXxodHRwOi8vcGljNS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MTEvOTcvNmYvYV8xMDA1NDUzMDdfbV82MDFfbTEwLmpwZw==",
          "vod_name": "淮水竹亭",
          "vod_pic": "http://pic5.iqiyipic.com/image/20250511/97/6f/a_100545307_m_601_m10.jpg",
          "vod_remarks": "更新至36集"
        },
        {
          "vod_id": "MzIxNDc3OTkwNTUwMzQwMXwyfOeBree9qnxodHRwOi8vcGljOC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjAvYzYvN2MvYV8xMDA2MTExNDBfbV82MDFfbTE2LmpwZw==",
          "vod_name": "灭罪",
          "vod_pic": "http://pic8.iqiyipic.com/image/20250520/c6/7c/a_100611140_m_601_m16.jpg",
          "vod_remarks": "更新至24集"
        },
        {
          "vod_id": "ODUwODI3MjMzNDQ3NDMwMXwyfOWcqOS6uumXtHxodHRwOi8vcGljMi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MjgvYmYvYzEvYV8xMDA1ODIzNzhfbV82MDFfbTYuanBn",
          "vod_name": "在人间",
          "vod_pic": "http://pic2.iqiyipic.com/image/20250528/bf/c1/a_100582378_m_601_m6.jpg",
          "vod_remarks": "更新至8集"
        },
        {
          "vod_id": "MjIxMTI3MDQzMDAyODMwMXwyfOeIseS9oHxodHRwOi8vcGljMi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTAzMTAvMGIvODUvYV8xMDA1Njg5MjdfbV82MDFfbTguanBn",
          "vod_name": "爱你",
          "vod_pic": "http://pic2.iqiyipic.com/image/20250310/0b/85/a_100568927_m_601_m8.jpg",
          "vod_remarks": "更新至28集"
        },
        {
          "vod_id": "MTQyNDM0NTczMzQzNDcwMXwyfOe7neWvhui+g+mHj3xodHRwOi8vcGljMS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA1MTMvZWQvNjEvYV8xMDA1NzU4NjNfbV82MDFfbTE0LmpwZw==",
          "vod_name": "绝密较量",
          "vod_pic": "http://pic1.iqiyipic.com/image/20250513/ed/61/a_100575863_m_601_m14.jpg",
          "vod_remarks": "更新至28集"
        },
        {
          "vod_id": "ODA3NzUwOTI3NDI1ODMwMXwyfOiOsuiKsealvHxodHRwOi8vcGljOS5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNDA5MjAvZTUvNDMvYV8xMDA1MTc2OTZfbV82MDFfbTM1LmpwZw==",
          "vod_name": "莲花楼",
          "vod_pic": "http://pic9.iqiyipic.com/image/20240920/e5/43/a_100517696_m_601_m35.jpg",
          "vod_remarks": "更新至40集"
        },
        {
          "vod_id": "NzQyNTM0ODQ0MDA3ODAwMXwyfOWUkOacneivoeS6i+W9leS5i+ilv+ihjHxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNDEwMjUvNzcvYWEvYV8xMDA1MzMzMDFfbV82MDFfbTEyLmpwZw==",
          "vod_name": "唐朝诡事录之西行",
          "vod_pic": "http://pic4.iqiyipic.com/image/20241025/77/aa/a_100533301_m_601_m12.jpg",
          "vod_remarks": "更新至40集"
        },
        {
          "vod_id": "MTk3MTQyMjg0MTU2NjMwMXwyfOWMl+S4inxodHRwOi8vcGljNi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTAzMzEvZjcvNTIvYV8xMDA1MzcyODRfbV82MDFfbTE2LmpwZw==",
          "vod_name": "北上",
          "vod_pic": "http://pic6.iqiyipic.com/image/20250331/f7/52/a_100537284_m_601_m16.jpg",
          "vod_remarks": "更新至38集"
        },
        {
          "vod_id": "MTIyNzgxNTEwMDc0ODIwMXwyfOWugeWuieWmguaipnxodHRwOi8vcGljMi5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNDA4MDYvZjQvZmMvYV8xMDA1MDg5NjlfbV82MDFfbTM2LmpwZw==",
          "vod_name": "宁安如梦",
          "vod_pic": "http://pic2.iqiyipic.com/image/20240806/f4/fc/a_100508969_m_601_m36.jpg",
          "vod_remarks": "更新至38集"
        },
        {
          "vod_id": "ODM1NTg2MDgyMzQwOTYwMXwyfOaIkeaYr+WIkeitpnxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNDEyMTMvNjUvMzQvYV8xMDA0ODA3NDBfbV82MDFfbTEzLmpwZw==",
          "vod_name": "我是刑警",
          "vod_pic": "http://pic4.iqiyipic.com/image/20241213/65/34/a_100480740_m_601_m13.jpg",
          "vod_remarks": "更新至38集"
        },
        {
          "vod_id": "NTMyODQ4NjkxNDE5MDEwMXwyfOeLgumjmXxodHRwOi8vcGljMC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyMzExMTMvOGIvMDQvYV8xMDA0NzYxNzRfbV82MDFfbTQ0LmpwZw==",
          "vod_name": "狂飙",
          "vod_pic": "http://pic0.iqiyipic.com/image/20231113/8b/04/a_100476174_m_601_m44.jpg",
          "vod_remarks": "更新至39集"
        },
        {
          "vod_id": "MjUzMjkzODkzNDk1NTcwMXwyfOS7meWPsOacieagkXxodHRwOi8vcGljNC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTAyMDUvNzAvZDMvYV8xMDA1NDY5MDNfbV82MDFfbTEyLmpwZw==",
          "vod_name": "仙台有树",
          "vod_pic": "http://pic4.iqiyipic.com/image/20250205/70/d3/a_100546903_m_601_m12.jpg",
          "vod_remarks": "更新至40集"
        },
        {
          "vod_id": "NDcwOTIxNDg3OTc2NzMwMXwyfOe0q+W3neS5i+WFieaYjueOi3xodHRwOi8vcGljMC5pcWl5aXBpYy5jb20vaW1hZ2UvMjAyNTA2MDUvNzUvZWYvYV8xMDA2MjQ0MDlfbV82MDFfbTIuanBn",
          "vod_name": "紫川之光明王",
          "vod_pic": "http://pic0.iqiyipic.com/image/20250605/75/ef/a_100624409_m_601_m2.jpg",
          "vod_remarks": "更新至24集"
        }
      ]
    };
  }
} 
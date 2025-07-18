import 'style.dart';
import 'package:flutter/material.dart';
import 'package:tapped/tapped.dart';

class VideoButtonColumn extends StatelessWidget {
  final double? bottomPadding;
  final bool isFavorite;
  final Function? onFavorite;
  final Function? onComment;
  final Function? onAvatar;

  const VideoButtonColumn({
    super.key,
    this.bottomPadding,
    this.onFavorite,
    this.onComment,
    this.isFavorite = false,
    this.onAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SysSize.avatar,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Tapped(
            onTap: onAvatar,
            child: VideoAvatar(
              onAvatar: onAvatar,
              size: 40.0,
            ),
          ),
          FavoriteIcon(
            onFavorite: onFavorite,
            isFavorite: isFavorite,
          ),
          _IconButton(
            icon: IconToText(Icons.mode_comment, size: SysSize.iconBig - 4),
            text: '4213',
            onTap: onComment,
          ),
        ],
      ),
    );
  }
}

class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({
    super.key,
    required this.onFavorite,
    this.isFavorite,
  });
  final bool? isFavorite;
  final Function? onFavorite;

  @override
  Widget build(BuildContext context) {
    return _IconButton(
      icon: IconToText(
        Icons.favorite,
        size: SysSize.iconBig,
        color: isFavorite! ? ColorPlate.red : null,
      ),
      text: '1.0w',
      onTap: onFavorite,
    );
  }
}

class VideoAvatar extends StatelessWidget {
  const VideoAvatar({
    super.key,
    this.onAvatar,
    this.size,
  });

  final Function? onAvatar;
  final double? size;

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size ?? SysSize.avatar,
      height: size ?? SysSize.avatar,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(size != null ? size! / 2.0 : SysSize.avatar / 2.0),
        color: Colors.orange,
      ),
      child: ClipOval(
        child: Image.network(
          "https://wpimg.wallstcn.com/f778738c-e4f8-4870-b634-56703b4acafe.gif",
          fit: BoxFit.cover,
        ),
      ),
    );
    Widget addButton = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorPlate.orange,
      ),
      child: Icon(
        Icons.add,
        size: 16,
      ),
    );
    return Container(
      width: size ?? SysSize.avatar,
      height: 66,
      margin: EdgeInsets.only(bottom: 6),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[avatar, addButton],
      ),
    );
  }
}

/// 把IconData转换为文字，使其可以使用文字样式
class IconToText extends StatelessWidget {
  final IconData? icon;
  final TextStyle? style;
  final double? size;
  final Color? color;

  const IconToText(
    this.icon, {
    super.key,
    this.style,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      String.fromCharCode(icon!.codePoint),
      style: style ??
          TextStyle(
            fontFamily: 'MaterialIcons',
            fontSize: size ?? 30,
            inherit: true,
            color: color ?? ColorPlate.white,
          ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final Widget? icon;
  final String? text;
  final Function? onTap;

  const _IconButton({
    this.icon,
    this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var shadowStyle = TextStyle(
      shadows: [
        Shadow(
          color: Colors.black.withAlpha(38),
          offset: Offset(0, 1),
          blurRadius: 1,
        ),
      ],
    );
    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Tapped(
          onTap: onTap,
          child: icon ?? Container(),
        ),
        Container(height: 2),
        Text(
          text ?? '??',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: SysSize.small,
            color: ColorPlate.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: DefaultTextStyle(
        style: shadowStyle,
        child: body,
      ),
    );
  }
}

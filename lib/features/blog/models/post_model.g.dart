// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostModelAdapter extends TypeAdapter<PostModel> {
  @override
  final int typeId = 0;

  @override
  PostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      coverImageUrl: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      authorName: fields[5] as String,
      userId: fields[6] as String,
      isPublished: fields[7] as bool,
      likesCount: fields[8] as int,
      isLikedByMe: fields[9] as bool,
      isBookmarkedByMe: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PostModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.coverImageUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.authorName)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.isPublished)
      ..writeByte(8)
      ..write(obj.likesCount)
      ..writeByte(9)
      ..write(obj.isLikedByMe)
      ..writeByte(10)
      ..write(obj.isBookmarkedByMe);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

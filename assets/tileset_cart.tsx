<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.2" name="tileset_cart" tilewidth="16" tileheight="16" tilecount="6" columns="3">
 <editorsettings>
  <export target="tileset_cart.lua" format="lua"/>
 </editorsettings>
 <image source="caves-rails-tileset-1.2/tileset_cart.png" width="48" height="32"/>
 <tile id="0">
  <properties>
   <property name="orientation" value="horizontal"/>
   <property name="state" value="empty"/>
   <property name="type" value="train_back"/>
  </properties>
 </tile>
 <tile id="1">
  <properties>
   <property name="orientation" value="horizontal"/>
   <property name="type" value="train_front"/>
  </properties>
 </tile>
 <tile id="2">
  <properties>
   <property name="orientation" value="vertical"/>
   <property name="type" value="train_front"/>
  </properties>
 </tile>
 <tile id="3">
  <properties>
   <property name="orientation" value="vertical"/>
   <property name="state" value="empty"/>
   <property name="type" value="train_back"/>
  </properties>
 </tile>
 <tile id="4">
  <properties>
   <property name="orientation" value="horizontal"/>
   <property name="state" value="full"/>
   <property name="type" value="train_back"/>
  </properties>
 </tile>
 <tile id="5">
  <properties>
   <property name="orientation" value="vertical"/>
   <property name="state" value="full"/>
   <property name="type" value="train_back"/>
  </properties>
 </tile>
</tileset>

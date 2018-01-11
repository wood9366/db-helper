# Database Helper
## Features
- [x] define database and table with config file
- [ ] distribute on mysql/mariadb server
## Environment
- Perl 5.18
## Usage
### Database Config File
Database config file, xml format, use to describe database and table structure. 
- name of databse, table or field better to use all lower case letter and underscore.
- ignore number of databae or table means only 1
- support field type
  * integer
    * u?int(8|16|32|64)?
    * prefix **u** means unsigned, otherwise signed
    * suffix 8,16,32,64 means the size of integer, no suffix means 32.
  * float
  * datetime
  * string
    * (var)?char(\\([0-9]+\\))?
    * prefix **var** means variable length of stirng, otherwise fixed
    * suffix (xxx) means maximum length of string
- about null field
  * field can't be null that means create table with all fields', except auto_increase field and field with default value
- support field extra property
  * auto_increase
    * if defined, that field is auto increase from specific value.
    * if no value specific, auto increase from 0.
  * default
    * give a default value of field, if create talbe without value of this field, the default value will be used
    * if field is auto_increase, default is no used
```xml
<config>
  <databases> <!-- define database list -->
    <database>
      <name>xxx</name> <!-- database name -->
    </database>
    ...
  </databases>
  <tables> <!-- define table list -->
    <table>
      <name>xxx</name> <!-- table name -->
      <num>50</num> <!-- number of table to split, no this element means 1 -->
      <database>xxx</database> <!-- database name this table belong to -->
      <fields> <!-- define table fields list -->
        <field>
          <name>xxx</name> <!-- field name -->
          <type>xxx</type> <!-- field type -->
          <auto_increase>0</auto_increase> <!-- field is auto increased -->
          ...
        </field>
        ...
      </fields>
      <keys> <!-- primary keys, define field name in order -->
        <key>xxx</key>
        <key>yyy</key>
        ...
      </keys>
    </table>
    ...
  </tables>
</config>
```
### Depoly Config File
Depoly config file, xml format, use to store depoly database server information.
* database **start** and **num** element
  * if not define, means only 1 database should be created.
  * with both start and num, means create more than one database, name is $dbname_$idx.
    * dbname is database's name
    * idx is [start, start + num), idx with 0 prefix depends on maximum number of idx. For example, maximum number of db is 100, so 3rd db's name is dbname_03.
```xml
<depoly>
  <connection>
    <name>self</name>
    <type>mariadb</type> <!-- database server type -->
    <host>127.0.0.1</host> <!-- database host -->
    <port>3306</port> <!-- database port -->
    <username>isg</username> <!-- database username -->
    <password>123456</password> <!-- database password -->
    <databases> <!-- database depoly info on this erver -->
      <database>
        <name>common</name> <!-- database name, use to find database config -->
      </database>
      <database>
        <name>ink_sanguo</name>
        <start>0</start>
        <num>100</num>
      </database>
      ...
    </databases>
  </connection>
</depoly>

```
# Database Helper
## Features
- [x] define database and table with config file
- [ ] distribute on mysql/mariadb server
## Environment
- Perl 5.18
## Usage
### Database Config File
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

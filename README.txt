# CLM_Dockerization

WAS architecture:

Single/Standalone:

  compose
    |
----------
|    |   |
DB2 CLM WAS-CLM

Multiple/Enterprise:

  compose
    |
---------------------------------------
|    |   |        |       |           |
DB2 CLM WAS-JTS WAS-DCC WAS-JRS WAS-CCM/WAS-RM/WAS-QM

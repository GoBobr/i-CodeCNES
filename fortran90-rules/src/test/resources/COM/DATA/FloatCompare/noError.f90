       INTEGER A,B,stab(3)
       REAL C,D
	   
       IF (A .EQ. B) THEN
            .TRUE.
       END IF
	  
       DO WHILE (C .LE. D)
           A = A + 1
       END DO
	 
	   IF ( stab(1) == 0) THEN  
     	   .TRUE.
  	   ELSEIF (stab(2) == 2) THEN 
   		   .TRUE.
   	   ELSE
     	   .TRUE.
   	   ENDIF

! Test: .AND. operator should not be flagged as a variable
program and_op_test
  implicit none
  integer :: a, b
  double precision :: x
  a = 1
  b = 2
  x = 0.5D0
  if (a == 1 .and. b == 2) then
    x = 1.0D0
  end if
  if (a == 1 .and. x > 0.D0) then
    x = 2.0D0
  end if
end program and_op_test

! Test: D0 literals should not be extracted as variables
program d0_literal_test
  implicit none
  integer :: i
  i = 0
  if (i == 0) then
    i = 1
  end if
end program d0_literal_test

! Test: Derived-type INTEGER components should not be flagged as float
program struct_test
  implicit none
  type :: my_type
    integer :: idx
    integer :: count
  end type my_type
  type(my_type) :: obj
  integer :: hidx
  hidx = 10
  obj%idx = 5
  if (obj%idx == hidx) then
    obj%count = 1
  end if
end program struct_test
	     
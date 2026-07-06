 PROGRAM ESSAI

      INTEGER i

	  IF ( .NOT. A .OR. .NOT. B) 
	  	i = 0
	  END IF
	   
  END PROGRAM

! Test: D0/E0 numeric literals should be recognized as DOUBLE PRECISION
program dnum_test
  implicit none
  double precision :: x, y
  integer :: i, m
  x = 0.D0
  y = 1.0D0
  x = DBLE(i)
  y = DBLE(8*m**3)
  if (x > 0.D0 .and. y < 1.D0) then
    x = 0.0D0
  end if
  x = DBLE(m - 1)/DBLE(8*m**3)
end program dnum_test

! Test: Same-type expressions should not be flagged as mixed type
program sametype_test
  implicit none
  double precision :: a, b, c
  a = 1.0D0
  b = 2.0D0
  c = a + b
  c = DBLE(1)/DBLE(2)
end program sametype_test

! Test: .AND. operator should not cause LOGICAL with CHARACTER error
program logic_test
  implicit none
  logical :: flag1, flag2
  double precision :: x
  x = 0.5D0
  flag1 = .true.
  flag2 = .false.
  if (x > 0.D0 .and. x < 1.D0) then
    flag1 = .true.
  end if
end program logic_test

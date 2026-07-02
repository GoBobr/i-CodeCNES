program test_eqv
  logical :: x, y
  x = .true.
  y = .false.
  if (x .EQV. .TRUE.) then
    y = .false.
  end if
  if (x .NEQV. .FALSE.) then
    y = .true.
  end if
end program test_eqv

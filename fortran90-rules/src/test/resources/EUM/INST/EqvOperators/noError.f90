program test_eqv
  logical :: x, y
  x = .true.
  y = .false.
  if (x .EQV. y) then
    y = .false.
  end if
  if (x .NEQV. y) then
    y = .true.
  end if
end program test_eqv

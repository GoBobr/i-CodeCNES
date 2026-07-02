program essai
  integer :: i
  open(unit=10, file='test.dat')
  read(10,*) i
  close(10)
end program essai

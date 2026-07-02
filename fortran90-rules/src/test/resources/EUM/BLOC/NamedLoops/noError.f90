program test_loops
  integer :: i, j
  outer: do i = 1, 10
    inner: do j = 1, 10
      print *, i, j
    end do inner
  end do outer
end program test_loops

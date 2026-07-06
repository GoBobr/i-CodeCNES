program ESSAI

    INTEGER, DIMENSION(:), POINTER :: C
    INTEGER, DIMENSION(:), ALLOCATABLE :: D

	allocate(C(n1), STAT = iom)

	deallocate(C, stat=iom)
	nullify  (C)
	! pointeur NULL

    ! ALLOCATABLE variable — NULLIFY not required after DEALLOCATE
    allocate(D(n2), STAT = iom)
    deallocate(D, stat=iom)

end program
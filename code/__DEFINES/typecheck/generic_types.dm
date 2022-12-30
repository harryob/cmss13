#define isdatum(X)                  (istype(X, /datum))
#define istypestrict(D, typepath)   D.type == typepath
#define ismind(X)                   (istype(X, /datum/mind))
#define isitem(X)                   (istype(X, /obj/item))
#define isStructure(X)              (istype(X, /obj/structure))
#define isVehicle(X)                (istype(X, /obj/vehicle))
#define isVehicleMultitile(X)       (istype(X, /obj/vehicle/multitile))
#define isclient(X)                 (istype(X, /client))
#define isStack(X)                  (istype(X, /obj/item/stack))
#define issurface(X)                (istype(X, /obj/structure/surface))
#define ismovableatom(A) 			(ismovable(A))
#define isatom(A) 					(isloc(A))

#define isfloorturf(A) (istype(A, /turf/open/floor))

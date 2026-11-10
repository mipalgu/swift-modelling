# Apply the Complete OCL document and write the result with the constraints inline
swift-ecore convert Timetable.ecore Timetable.oclinecore --ocl timetable-rules.ocl
cat Timetable.oclinecore

# Output:
# Conversion completed: Timetable.oclinecore
# import ecore : 'http://www.eclipse.org/emf/2002/Ecore#/';
#
# package timetable : tt = 'http://www.example.org/timetable'
# {
#     class Timetable
#     {
#         invariant UniqueRoomNames: rooms->isUnique(r | r.name);
#         invariant EnoughSeats: rooms->collect(r | r.seats)->sum() >= 100;
#         property rooms : Room[*] { composes, ordered };
#         property sessions : Session[*] { composes, ordered };
#     }
#     class Room
#     {
#         invariant PositiveSeats: seats > 0;
#         attribute name : String { ordered };
#         attribute seats : ecore::EInt { ordered };
#     }
#     class Session
#     {
#         invariant WithinTeachingDay: startHour >= 8 and startHour + durationHours <= 18;
#         invariant FitsRoom: attendees <= room.seats;
#         attribute courseCode : String { ordered };
#         attribute startHour : ecore::EInt { ordered };
#         attribute durationHours : ecore::EInt { ordered };
#         attribute attendees : ecore::EInt { ordered };
#         property room : Room { ordered };
#     }
# }

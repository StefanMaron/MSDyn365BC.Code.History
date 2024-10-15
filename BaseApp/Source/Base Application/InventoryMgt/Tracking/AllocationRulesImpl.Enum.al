namespace Microsoft.Inventory.Tracking;

enum 300 "Allocation Rules Impl." implements "Allocate Reservation"
{
    Extensible = true;
    UnknownValueImplementation = "Allocate Reservation" = "Allocate Reserv. Basic";
    DefaultImplementation = "Allocate Reservation" = "Allocate Reserv. Basic";

    value(0; " ")
    {

    }
    value(1; "Basic (No Conflicts)")
    {
        Caption = 'Basic (No Conflicts)';
        Implementation = "Allocate Reservation" = "Allocate Reserv. Basic";
    }
    value(2; Equally)
    {
        Caption = 'Equally';
        Implementation = "Allocate Reservation" = "Allocate Reserv. Equally";
    }
}
namespace Microsoft.Inventory.Tracking;

interface "Allocate Reservation"
{
    procedure Allocate(var ReservationWkshLine: Record "Reservation Wksh. Line");

    procedure DeleteAllocation(var ReservationWkshLine: Record "Reservation Wksh. Line");

    procedure AllocationCompleted(var ReservationWkshLine: Record "Reservation Wksh. Line"): Boolean;

    procedure GetDescription(): Text;
}
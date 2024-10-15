// TODO:: GST Credit Enum should be used instead of creating a new enum

enum 18201 "GST Distribution Credit Type"
{
    Extensible = true;

    value(0; " ") { Caption = ''; }
    value(1; Availment) { Caption = 'Availment'; }
    value(2; "Non-Availment") { Caption = 'Non-Availment'; }
}
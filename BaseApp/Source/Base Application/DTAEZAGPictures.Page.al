page 3010543 "DTA EZAG Pictures"
{
    Caption = 'DTA EZAG Pictures';
    PageType = Card;
    SourceTable = "DTA Setup";

    layout
    {
        area(content)
        {
            field("EZAG Bar Code"; "EZAG Bar Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Elektronischer Zahlungsauftrag (EZAG) bar code that is associated with the bank code for DTA processing.';
            }
            field("EZAG Post Logo"; "EZAG Post Logo")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Elektronischer Zahlungsauftrag (EZAG) post logo that is associated with the bank code for DTA processing.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if "DTA/EZAG" <> "DTA/EZAG"::EZAG then
            Error(Text003);
    end;

    var
        Text001: Label 'Do you want to replace the existing picture of %1 %2?';
        Text002: Label 'Do you want to delete the picture of %1 %2?';
        PictureExists: Boolean;
        Text003: Label 'You can only add Pictures for EZAG.';
}


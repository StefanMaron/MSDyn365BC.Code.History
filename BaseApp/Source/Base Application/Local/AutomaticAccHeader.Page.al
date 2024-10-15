#if not CLEAN22
page 11206 "Automatic Acc. Header"
{
    Caption = 'Automatic Acc. Groups';
    PageType = ListPlus;
    SourceTable = "Automatic Acc. Header";
    ObsoleteReason = 'Moved to Automatic Account Codes app.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the automatic account group number in this field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an appropriate description of the automatic account group in this field.';
                }
            }
            part(AccLines; "Automatic Acc. Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Automatic Acc. No." = FIELD("No.");
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureKeyManagemnt: Codeunit "Feature Key Management";
    begin
        if FeatureKeyManagemnt.IsAutomaticAccountCodesEnabled() then begin
            Page.Run(4850); // page 4850 "Automatic Account Group"
            Error('');
        end;
    end;
}
#endif

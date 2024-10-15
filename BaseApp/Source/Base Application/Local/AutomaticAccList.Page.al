#if not CLEAN22
page 11208 "Automatic Acc. List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Automatic Account Groups';
    CardPageID = "Automatic Acc. Groups";
    Editable = false;
    PageType = List;
    SourceTable = "Automatic Acc. Header";
    UsageCategory = Lists;
    ObsoleteReason = 'Moved to Automatic Account Codes app.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the automatic account group number in this field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an appropriate description of the automatic account group in this field.';
                }
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
            Page.Run(4852); // page 4852 "Automatic Account List"
            Error('');
        end;
    end;
}
#endif


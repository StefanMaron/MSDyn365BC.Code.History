page 4704 "VAT Group Member Calculation"
{
    PageType = List;
    SourceTable = "VAT Group Calculation";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(BoxNo; "Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the box number of the VAT return.';
                }
                field("Group Member Name"; "Group Member Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the group member that submitted the VAT report.';
                }
                field("VAT Group Submission No."; "VAT Group Submission No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the VAT return from the group member that submitted it.';
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
                    begin
                        if VATGroupSubmissionHeader.Get(Rec."VAT Group Submission ID") then
                            Page.Run(Page::"VAT Group Submission", VATGroupSubmissionHeader);
                    end;
                }
                field(SubmittedOn; "Submitted On")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the timestamp during which the VAT report was submitted.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount for the specified box number.';
                }
            }
            group(Totals)
            {
                field(Total; Total)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount for the specified box number aggregated from all the group member returns.';
                    Caption = 'Total';
                }
            }

        }
    }

    var
        Total: Decimal;

    trigger OnOpenPage()
    begin
        Total := Rec.GetTotal();
    end;
}
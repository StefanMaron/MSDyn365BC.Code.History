page 4700 "VAT Group Submission Lines"
{
    PageType = ListPart;
    SourceTable = "VAT Group Submission Line";
    DelayedInsert = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = ID;
    Extensible = false;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(vatGroupSubmissionNo; "VAT Group Submission No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'vatGroupSubmissionNo', Locked = true;
                    ToolTip = 'Specifies the identifier for the VAT return from the group member that submitted it.';
                }
                field(lineNo; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'lineNo', Locked = true;
                    ToolTip = 'Specifies the number of the line on the VAT return from the group member that submitted it.';
                }
                field(rowNo; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'rowNo', Locked = true;
                    ToolTip = 'Specifies the row number of the VAT return from the group member that submitted it.';
                }
                field(description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'description', Locked = true;
                    ToolTip = 'Specifies a description for the VAT group submission line.';
                }
                field(boxNo; "Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'boxNo', Locked = true;
                    ToolTip = 'Specifies the box number of the VAT return.';
                }
                field(amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'amount', Locked = true;
                    ToolTip = 'Specifies the VAT amount for the specified box number.';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec.HasFilter() then
            Rec.Validate("VAT Group Submission ID", Rec.GetFilter("VAT Group Submission ID"));

        Rec.Insert(true);
        exit(false);
    end;
}
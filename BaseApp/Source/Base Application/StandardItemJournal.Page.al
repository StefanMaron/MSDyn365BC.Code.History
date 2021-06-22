page 754 "Standard Item Journal"
{
    Caption = 'Standard Item Journal';
    PageType = ListPlus;
    SourceTable = "Standard Item Journal";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the record in the line of the journal.';
                }
            }
            part(StdItemJnlLines; "Standard Item Journal Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                              "Standard Journal Code" = FIELD(Code);
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if xRec.Code = '' then
            SetRange(Code, Code);
    end;
}


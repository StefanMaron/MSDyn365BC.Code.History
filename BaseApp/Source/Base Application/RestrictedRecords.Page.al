page 1550 "Restricted Records"
{
    ApplicationArea = Suite;
    Caption = 'Restricted Records';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Restricted Record";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the record in the Restricted Record table.';
                    Visible = false;
                }
                field(RecordDetails; RecordDetails)
                {
                    ApplicationArea = Suite;
                    Caption = 'Record Details';
                    ToolTip = 'Specifies details about what imposed the restriction on the record.';
                }
                field(Details; Details)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies details about what imposed the restriction on the record.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Record")
            {
                ApplicationArea = Suite;
                Caption = 'Record';
                Image = Document;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open the record that is restricted from certain usage, as defined by the workflow response.';

                trigger OnAction()
                begin
                    ShowRecord;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RecordDetails := Format("Record ID", 0, 1);
    end;

    trigger OnAfterGetRecord()
    begin
        RecordDetails := Format("Record ID", 0, 1);
    end;

    var
        RecordDetails: Text;
}


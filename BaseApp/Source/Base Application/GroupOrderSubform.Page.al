page 17375 "Group Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Group Order Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Supplement No."; "Supplement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Name"; "Employee Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Get Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Contracts';
                    Ellipsis = true;
                    Image = Agreement;

                    trigger OnAction()
                    begin
                        GetContracts;
                    end;
                }
            }
        }
    }

    var
        LaborContractMgt: Codeunit "Labor Contract Management";

    [Scope('OnPrem')]
    procedure GetContracts()
    var
        GroupOrderLine: Record "Group Order Line";
    begin
        CurrPage.Update(true);
        GroupOrderLine.Copy(Rec);
        if "Line No." = 0 then begin
            GroupOrderLine := xRec;
            if GroupOrderLine.Next = 0 then
                GroupOrderLine."Line No." := xRec."Line No." + 10000;
        end;
        LaborContractMgt.InsertContracts(GroupOrderLine);
    end;
}


page 6073 "Filed Service Contract List"
{
    Caption = 'Filed Service Contract List';
    CardPageID = "Filed Service Contract";
    DataCaptionFields = "Contract No. Relation";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Filed Service Contract Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("File Date"; "File Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service contract or contract quote is filed.';
                }
                field("File Time"; "File Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service contract or contract quote is filed.';
                }
                field("Filed By"; "Filed By")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the user who filed the service contract.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Filed By");
                    end;
                }
                field("Contract Type"; "Contract Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the filed contract or contract quote.';
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the filed service contract or service contract quote.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the filed service contract or contract quote.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items in the filed service contract or contract quote.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the customer in the filed service contract or contract quote.';
                }
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

    trigger OnInit()
    begin
        CurrPage.LookupMode := false;
    end;
}


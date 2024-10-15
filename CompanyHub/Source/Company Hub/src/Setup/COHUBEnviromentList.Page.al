page 1166 "COHUB Enviroment List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "COHUB Enviroment";
    Caption = 'Enviroments';
    Editable = false;
    CardPageId = "COHUB Enviroment Card";

    layout
    {
        area(Content)
        {
            repeater(MainRepeater)
            {
                Editable = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the No. of the enviroment.';
                }

                field("Name"; Rec."Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the enviroment.';
                }

                field("Phone No."; Rec."Contact Phone No.")
                {
                    Caption = 'Phone No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the primary contact''s telephone number.';
                }

                field(Contact; Rec."Contact Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the primary contact.';
                }

                field(Link; Rec.Link)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the link that is used to access companies in the environment.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportEnviroments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Enviroments';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Imports data about environments and companies from a file.';

                trigger OnAction()
                var
                    COHUBCore: Codeunit "COHUB Core";
                begin
                    COHUBCore.ImportEnviroments();
                end;
            }

            action(ExportEnviroments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Enviroments';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Exports the list of enviroments.';

                trigger OnAction()
                var
                    COHUBCore: Codeunit "COHUB Core";
                begin
                    COHUBCore.ExportEnviroments();
                end;
            }

            action("Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enviroment Groups';
                Image = CustomerGroup;
                RunObject = page "COHUB Group List";
                ToolTip = 'Show enviroment groups.';
                Visible = true;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
            }
        }
    }
}

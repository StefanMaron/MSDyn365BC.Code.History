namespace Microsoft.Service.Maintenance;

page 5990 Troubleshooting
{
    Caption = 'Troubleshooting';
    PageType = ListPlus;
    SourceTable = "Troubleshooting Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the troubleshooting issue.';
                }
            }
            part(Control7; "Troubleshooting Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("No.");
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
        area(navigation)
        {
            group("T&roublesh.")
            {
                Caption = 'T&roublesh.';
                Image = Setup;
                action(Setup)
                {
                    ApplicationArea = Service;
                    Caption = 'Setup';
                    Image = Setup;
                    ToolTip = 'Set up troubleshooting.';

                    trigger OnAction()
                    begin
                        TblshtgSetup.Reset();
                        TblshtgSetup.SetCurrentKey("Troubleshooting No.");
                        TblshtgSetup.SetRange("Troubleshooting No.", Rec."No.");
                        PAGE.RunModal(PAGE::"Troubleshooting Setup", TblshtgSetup)
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if CaptionCode <> '' then
            CurrPage.Caption := CaptionCode + ' ' + CaptionDescription + ' - ' + CurrPage.Caption;
    end;

    var
        TblshtgSetup: Record "Troubleshooting Setup";
        CaptionCode: Code[20];
        CaptionDescription: Text[30];

    procedure SetCaption(CaptionCode2: Code[20]; CaptionDescription2: Text[30])
    begin
        CaptionCode := CaptionCode2;
        CaptionDescription := CaptionDescription2;
    end;
}


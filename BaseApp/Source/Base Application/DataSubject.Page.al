page 1754 "Data Subject"
{
    Extensible = false;
    DeleteAllowed = false;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Data Privacy Entities";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = StandardAccent;
                    StyleExpr = TRUE;

                    trigger OnDrillDown()
                    begin
                        PAGE.Run("Page No.");
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Data Privacy Setup")
            {
                ApplicationArea = All;
                Caption = 'Data Privacy Utility';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open the Data Privacy Setup page.';

                trigger OnAction()
                var
                    DataPrivacyWizard: Page "Data Privacy Wizard";
                begin
                    if "Table Caption" <> '' then begin
                        DataPrivacyWizard.SetEntitityType(Rec, "Table Caption");
                        DataPrivacyWizard.RUNMODAL;
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.RaiseOnGetDataPrivacyEntities(Rec);
    end;
}


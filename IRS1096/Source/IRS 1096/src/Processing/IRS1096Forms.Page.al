page 10019 "IRS 1096 Forms"
{
    Caption = '1096 Forms';
    PageType = List;
    SourceTable = "IRS 1096 Form Header";
    CardPageId = "IRS 1096 Form";
    Editable = false;
    RefreshOnActivate = true;
    ApplicationArea = BasicUS;
    UsageCategory = Lists;
    PromotedActionCategories = 'New,Process,Report,Approve,Release,Print';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the unique number of the form.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the starting date of the form.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the ending date of the form.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the status of the form. Only released forms can be printed. Only opened forms can be changed.';
                }
                field("IRS Code"; Rec."IRS Code")
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the IRS code of the form.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksFactBox; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesFactBox; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateForms)
            {
                ApplicationArea = BasicUS;
                Caption = 'Create Forms';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = True;
                Ellipsis = true;
                Image = Create;
                ToolTip = 'Create new 1096 forms for a certain period per each IRS code.';
                RunObject = report "IRS 1096 Create Forms";
            }
            action(PrintSingle)
            {
                ApplicationArea = BasicUS;
                Caption = 'Print-Single';
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = True;
                Ellipsis = true;
                Image = PrintAcknowledgement;
                ToolTip = 'Prints a single form.';

                trigger OnAction()
                var
                    IRS1096FormMgt: Codeunit "IRS 1096 Form Mgt.";
                begin
                    IRS1096FormMgt.PrintSingleForm(Rec);
                end;
            }
            action(PrintPerPeriod)
            {
                ApplicationArea = BasicUS;
                Caption = 'Print-Per Period';
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = True;
                Ellipsis = true;
                Image = PrintCover;
                ToolTip = 'Prints all forms within period.';

                trigger OnAction()
                var
                    IRS1096FormMgt: Codeunit "IRS 1096 Form Mgt.";
                begin
                    IRS1096FormMgt.PrintFormByPeriod(Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        IRS1096FormMgt: Codeunit "IRS 1096 Form Mgt.";
    begin
        if not IRS1096FormMgt.IsFeatureEnabled() then begin
            IRS1096FormMgt.ShowNotEnabledMessage(CurrPage.Caption());
            Error('');
        end;
    end;
}
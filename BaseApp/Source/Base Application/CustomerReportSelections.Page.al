page 9657 "Customer Report Selections"
{
    Caption = 'Document Layouts';
    DataCaptionFields = "Source No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Custom Report Selection";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                FreezeColumn = "Custom Report Description";
                field(Usage2; Usage2)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Usage';
                    OptionCaption = 'Quote,Confirmation Order,Invoice,Credit Memo,Customer Statement,Job Quote,Reminder,Shipment';
                    ToolTip = 'Specifies which type of document the report is used for.';

                    trigger OnValidate()
                    begin
                        case Usage2 of
                            Usage2::Quote:
                                Usage := Usage::"S.Quote";
                            Usage2::"Confirmation Order":
                                Usage := Usage::"S.Order";
                            Usage2::Invoice:
                                Usage := Usage::"S.Invoice";
                            Usage2::"Credit Memo":
                                Usage := Usage::"S.Cr.Memo";
                            Usage2::"Customer Statement":
                                Usage := Usage::"C.Statement";
                            Usage2::"Job Quote":
                                Usage := Usage::JQ;
                            Usage2::Reminder:
                                Usage := Usage::Reminder;
                            Usage2::Shipment:
                                Usage := Usage::"S.Shipment";
                        end;
                    end;
                }
                field(ReportID; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report ID';
                    ToolTip = 'Specifies the ID of the report.';
                }
                field(ReportCaption; "Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Caption';
                    ToolTip = 'Specifies the name of the report.';
                }
                field("Custom Report Description"; "Custom Report Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Custom Layout Description';
                    DrillDown = true;
                    Lookup = true;
                    ToolTip = 'Specifies a description of the custom report layout.';

                    trigger OnDrillDown()
                    begin
                        LookupCustomReportDescription;
                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupCustomReportDescription;
                        CurrPage.Update(true);
                    end;

                    trigger OnValidate()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if "Custom Report Description" = '' then begin
                            Validate("Custom Report Layout Code", '');
                            Modify(true);
                        end else begin
                            CustomReportLayout.SetRange("Report ID", "Report ID");
                            CustomReportLayout.SetFilter(Description, StrSubstNo('@*%1*', "Custom Report Description"));
                            if not CustomReportLayout.FindFirst then
                                Error(CouldNotFindCustomReportLayoutErr, "Custom Report Description");

                            Validate("Custom Report Layout Code", CustomReportLayout.Code);
                            Modify(true);
                        end;
                    end;
                }
                field(SendToEmail; "Send To Email")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send To Email';
                    ToolTip = 'Specifies that the report is used when sending emails.';

                    trigger OnAssistEdit()
                    begin
                        ShowSelectedContacts();
                    end;
                }
                field("Use for Email Body"; "Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';
                }
                field("Email Body Layout Code"; "Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; "Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Lookup = true;
                    ToolTip = 'Specifies a description of the email body layout that is used.';

                    trigger OnDrillDown()
                    begin
                        LookupEmailBodyDescription;
                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupEmailBodyDescription;
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyFromReportSelectionsAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy from Report Selection';
                Image = Copy;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Copy reports that are set up on the Report Selection page.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    CustomReportSelection: Record "Custom Report Selection";
                begin
                    CustomReportSelection := Rec;
                    FilterCustomerUsageReportSelections(ReportSelections);
                    CopyFromReportSelections(ReportSelections, Database::Customer, GetFilter("Source No."));
                    CurrPage.SetRecord(CustomReportSelection);
                end;
            }

            action(SelectFromContactsAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Email from Contacts';
                Image = ContactFilter;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Select an email address from the list of contacts.';

                trigger OnAction()
                var
                    ContBusRel: Record "Contact Business Relation";
                begin
                    GetSendToEmailFromContactsSelection(ContBusRel."Link to Table"::Customer, GetFilter("Source No."));
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        MapTableUsageValueToPageValue;
        GetSendToEmail(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        InitUsage;
        MapTableUsageValueToPageValue;
    end;

    var
        Usage2: Option Quote,"Confirmation Order",Invoice,"Credit Memo","Customer Statement","Job Quote",Reminder,Shipment;
        CouldNotFindCustomReportLayoutErr: Label 'There is no custom report layout with %1 in the description.', Comment = '%1 Description of custom report layout';

    local procedure MapTableUsageValueToPageValue()
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        case Usage of
            CustomReportSelection.Usage::"S.Quote":
                Usage2 := Usage::"S.Quote";
            CustomReportSelection.Usage::"S.Order":
                Usage2 := Usage::"S.Order";
            CustomReportSelection.Usage::"S.Invoice":
                Usage2 := Usage::"S.Invoice";
            CustomReportSelection.Usage::"S.Cr.Memo":
                Usage2 := Usage::"S.Cr.Memo";
            CustomReportSelection.Usage::"C.Statement":
                Usage2 := Usage2::"Customer Statement";
            CustomReportSelection.Usage::JQ:
                Usage2 := Usage2::"Job Quote";
            CustomReportSelection.Usage::Reminder:
                Usage2 := Usage2::Reminder;
            CustomReportSelection.Usage::"S.Shipment":
                Usage2 := Usage2::Shipment;
        end;
    end;

    local procedure FilterCustomerUsageReportSelections(var ReportSelections: Record "Report Selections")
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        ReportSelections.SetFilter(
            Usage, '%1|%2|%3|%4|%5|%6|%7|%8',
            CustomReportSelection.Usage::"S.Quote",
            CustomReportSelection.Usage::"S.Order",
            CustomReportSelection.Usage::"S.Invoice",
            CustomReportSelection.Usage::"S.Cr.Memo",
            CustomReportSelection.Usage::"C.Statement",
            CustomReportSelection.Usage::JQ,
            CustomReportSelection.Usage::Reminder,
            CustomReportSelection.Usage::"S.Shipment");
    end;
}


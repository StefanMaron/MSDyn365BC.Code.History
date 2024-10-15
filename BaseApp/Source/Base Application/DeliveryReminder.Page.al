page 5005270 "Delivery Reminder"
{
    Caption = 'Delivery Reminder';
    PageType = Document;
    SourceTable = "Delivery Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the delivery reminder header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who the delivery reminder is for.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the vendor.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies another line of the address.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/City';
                    ToolTip = 'Specifies the postal code of the address.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the address.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of your regular contact when you communicate with the vendor.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the deliver reminder should be issued.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when you created the delivery reminder.';
                }
                field("Reminder Level"; "Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the delivery reminder''s level.';
                }
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s delivery reminder terms code.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the delivery reminder is due.';
                }
            }
            part(DeliveryReminderLines; "Delivery Reminder Sub.")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Reminder")
            {
                Caption = '&Reminder';
                Image = Reminder;
                action("V&endor")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'V&endor';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    RunPageLink = "No." = FIELD("Vendor No.");
                    ToolTip = 'View detailed information for the vendor.';
                }
                action("Co&mment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mment';
                    Image = ViewComments;
                    RunObject = Page "Delivery Reminder Comment Line";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "No.", "Line No.")
                                  WHERE("Document Type" = CONST("Delivery Reminder"));
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(creation)
        {
            action("Delivery Reminder")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder';
                Image = ReceiptReminder;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "Delivery Reminder";
                RunPageMode = Create;
                ToolTip = 'Create a reminder to a vendor about late delivery.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateDeliveryReminder)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Delivery Reminder';
                    Ellipsis = true;
                    Image = CreateReminders;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a reminder to a vendor about late delivery.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Create Delivery Reminder");
                    end;
                }
                action(SuggestReminderLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Reminder Lines';
                    Image = SuggestReminderLines;
                    ToolTip = 'Create reminder lines in existing reminders for any late deliveries based on information in the Delivery Reminder window.';

                    trigger OnAction()
                    begin
                        DeliveryReminderHeader := Rec;
                        CreateDeliveryReminder.SuggestLines(DeliveryReminderHeader);
                    end;
                }
                action("Update Reminder Text")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Reminder Text';
                    Image = RefreshText;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Replace the beginning and ending text that has been defined for the related reminder level with those from a different level.';

                    trigger OnAction()
                    begin
                        DeliveryReminderHeader := Rec;
                        CreateDeliveryReminder.UpdateLines(DeliveryReminderHeader);
                    end;
                }
            }
            group("&Issuing")
            {
                Caption = '&Issuing';
                Image = Add;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        PrintDocumentProfessional.DeliveryRemindPrint(Rec);
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the specified reminder entries according to your specifications in the Delivery Reminder Terms window.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        DeliverTok: Label 'DACH Delivery Reminder', Locked = true;
                    begin
                        FeatureTelemetry.LogUptake('0001Q0S', DeliverTok, Enum::"Feature Uptake Status"::"Used");
                        DeliveryReminderHeader := Rec;
                        DeliveryReminderHeader.SetRecFilter;
                        REPORT.RunModal(REPORT::"Issue Delivery Reminder", true, true, DeliveryReminderHeader);
                        FeatureTelemetry.LogUsage('0001Q0T', DeliverTok, 'DACH delivery reminder set up');
                    end;
                }
            }
        }
    }

    var
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
        PrintDocumentProfessional: Codeunit "Print Document Comfort";
}


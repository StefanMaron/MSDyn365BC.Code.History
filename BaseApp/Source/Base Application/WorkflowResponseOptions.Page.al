page 1523 "Workflow Response Options"
{
    Caption = 'Workflow Response Options';
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = "Workflow Step Argument";

    layout
    {
        area(content)
        {
            group(Control5)
            {
                ShowCaption = false;
                group(Control14)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 0';
                    field(NoArguments; NoArguments)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;
                    }
                }
                group(Control7)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 1';
                    field("General Journal Template Name"; "General Journal Template Name")
                    {
                        ApplicationArea = Suite;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the name of the general journal template that is used for this workflow step argument.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true)
                        end;
                    }
                    field("General Journal Batch Name"; "General Journal Batch Name")
                    {
                        ApplicationArea = Suite;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the name of the general journal batch that is used for this workflow step argument.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true)
                        end;
                    }
                }
                group(Control8)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 2';
                    field(NotifySender2; "Notify Sender")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Notify Sender';
                        ToolTip = 'Specifies if the approval sender will be notified in connection with this workflow step argument.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true)
                        end;
                    }
                    field("Link Target Page Approvals"; "Link Target Page")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Link Target Page';
                        ToolTip = 'Specifies a specific page that opens when a user chooses the link in a notification. If you do not fill this field, the page showing the involved record will open. The page must have the same source table as the record involved.';
                    }
                    field("Custom Link Approvals"; "Custom Link")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Custom Link';
                        ToolTip = 'Specifies a link that is inserted in the notification to link to a custom location.';
                    }
                }
                group(Control23)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 3';
                    field(NotifySender3; "Notify Sender")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Notify Sender';
                        ToolTip = 'Specifies if the approval sender will be notified in connection with this workflow step argument.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true)
                        end;
                    }
                    field("Notification User ID"; "Notification User ID")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recipient User ID';
                        Editable = not "Notify Sender";
                        ShowMandatory = not "Notify Sender";
                        ToolTip = 'Specifies the ID of the user that will be notified in connection with this workflow step argument.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true)
                        end;
                    }
                    field("Notification Entry Type"; "Notification Entry Type")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Notification Entry Type';
                        ToolTip = 'Specifies the type of the notification.';
                    }
                    field("Link Target Page"; "Link Target Page")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Link Target Page';
                        ToolTip = 'Specifies a specific page that opens when a user chooses the link in a notification. If you do not fill this field, the page showing the involved record will open. The page must have the same source table as the record involved.';
                    }
                    field("Custom Link"; "Custom Link")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies a link that is inserted in the notification to link to a custom location.';
                    }
                }
                group(Control6)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 4';
                    field(MessageField; Message)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Message';
                        ToolTip = 'Specifies the message that will be shown as a response.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true)
                        end;
                    }
                }
                group(Control10)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 5';
                    field("Show Confirmation Message"; "Show Confirmation Message")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies that a confirmation message is shown to users after they request an approval.';
                    }
                    field("Due Date Formula"; "Due Date Formula")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies in how many days the approval request must be resolved from the date when it was sent.';
                    }
                    field("Delegate After"; "Delegate After")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies if and when an approval request will automatically be delegated to the relevant substitute. You can select to automatically delegate one, two, or five days after the date when the approval was requested.';
                    }
                    field("Approver Type"; "Approver Type")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies who is notified first about approval requests.';

                        trigger OnValidate()
                        begin
                            SetVisibilityOptions;
                            CurrPage.Update(true)
                        end;
                    }
                    group(Control4)
                    {
                        ShowCaption = false;
                        Visible = ShowApprovalLimitType;
                        field("Approver Limit Type"; "Approver Limit Type")
                        {
                            ApplicationArea = Suite;
                            ToolTip = 'Specifies how approvers'' approval limits affect when approval request entries are created for them. A qualified approver is an approver whose approval limit is above the value on the approval request.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true)
                            end;
                        }
                    }
                    group(Control18)
                    {
                        ShowCaption = false;
                        Visible = NOT ShowApprovalLimitType;
                        field("Workflow User Group Code"; "Workflow User Group Code")
                        {
                            ApplicationArea = Suite;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the workflow user group that is used in connection with this workflow step argument.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true)
                            end;
                        }
                    }
                    group(Control34)
                    {
                        ShowCaption = false;
                        Visible = ShowApproverUserId;
                        field(ApproverId; "Approver User ID")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Approver ID';
                            ShowMandatory = true;
                            ToolTip = 'Specifies the approver.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true)
                            end;
                        }
                    }
                    field(ApprovalUserSetupLabel; ApprovalUserSetupLabel)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            PAGE.RunModal(PAGE::"Approval User Setup");
                        end;
                    }
                }
                group(Control27)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 6';
                    field(TableFieldRevert; TableFieldCaption)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Field';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the field in which a change can occur that the workflow monitors.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GetEventTable;
                            Text := LookupFieldCaption(Format("Table No."), '');
                            exit(Text <> '')
                        end;

                        trigger OnValidate()
                        begin
                            ValidateFieldCaption;
                        end;
                    }
                }
                group(Control29)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 7';
                    field(ApplyAllValues; ApplyAllValues)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Apply All New Values';
                        ToolTip = 'Specifies that all the new, approved values will be applied to the record.';

                        trigger OnValidate()
                        begin
                            if ApplyAllValues then begin
                                "Table No." := 0;
                                "Field No." := 0;
                                CurrPage.Update(true);
                            end;
                        end;
                    }
                    group(Control32)
                    {
                        ShowCaption = false;
                        Visible = NOT ApplyAllValues;
                        field(TableFieldApply; TableFieldCaption)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Field';
                            ShowMandatory = true;
                            ToolTip = 'Specifies the field in which a change can occur that the workflow monitors.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Text := LookupFieldCaptionForApplyNewValues;
                                exit(Text <> '')
                            end;

                            trigger OnValidate()
                            begin
                                ValidateFieldCaption;
                            end;
                        }
                    }
                }
                group(Control35)
                {
                    ShowCaption = false;
                    Visible = "Response Option Group" = 'GROUP 8';
                    field("Response Type"; "Response Type")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies the response type for the workflow response. You cannot set options for this.';

                        trigger OnValidate()
                        begin
                            SetVisibilityOptions;
                            CurrPage.Update(true)
                        end;
                    }
                    group(Control37)
                    {
                        ShowCaption = false;
                        Visible = ShowResponseUserID;
                        field(ResponseUserId; "Response User ID")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Response User ID';
                            ShowMandatory = true;
                            ToolTip = 'Specifies the user necessary for an acceptable response.';

                            trigger OnValidate()
                            begin
                                CurrPage.Update(true);
                            end;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetVisibilityOptions;
        GetEventTable;
        CalcFields("Field Caption");
        TableFieldCaption := "Field Caption";
        ApplyAllValues := ("Field No." = 0);
    end;

    trigger OnAfterGetRecord()
    begin
        SetVisibilityOptions;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Find(Which));
    end;

    trigger OnOpenPage()
    var
        ApprovalUserSetup: Page "Approval User Setup";
    begin
        NoArguments := NoArgumentsTxt;
        ApprovalUserSetupLabel := StrSubstNo(OpenPageTxt, ApprovalUserSetup.Caption);
        HideExternalUsers;
    end;

    var
        NoArguments: Text;
        NoArgumentsTxt: Label 'You cannot set options for this workflow response.';
        ShowApprovalLimitType: Boolean;
        ShowApproverUserId: Boolean;
        ApprovalUserSetupLabel: Text;
        OpenPageTxt: Label 'Open %1', Comment = '%1 is the page that will be opened when clicking the control';
        TableFieldCaption: Text;
        ApplyAllValues: Boolean;
        ShowResponseUserID: Boolean;

    local procedure GetEventTable()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepEvent: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowStep.SetRange(Argument, ID);
        if WorkflowStep.FindFirst then
            if WorkflowStep.HasParentEvent(WorkflowStepEvent) then begin
                WorkflowEvent.Get(WorkflowStepEvent."Function Name");
                "Table No." := WorkflowEvent."Table ID";
            end;
    end;

    local procedure SetVisibilityOptions()
    begin
        CalcFields("Response Option Group");
        ShowApprovalLimitType := "Approver Type" <> "Approver Type"::"Workflow User Group";
        ShowApproverUserId := ShowApprovalLimitType and ("Approver Limit Type" = "Approver Limit Type"::"Specific Approver");
        ShowResponseUserID := "Response Type" = "Response Type"::"User ID";
    end;

    local procedure LookupFieldCaption(TableNoFilter: Text; FieldNoFilter: Text): Text
    var
        "Field": Record "Field";
        FieldSelection: Codeunit "Field Selection";
    begin
        Field.FilterGroup(2);
        Field.SetFilter(Type, StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12',
            Field.Type::Boolean,
            Field.Type::Text,
            Field.Type::Code,
            Field.Type::Decimal,
            Field.Type::Integer,
            Field.Type::BigInteger,
            Field.Type::Date,
            Field.Type::Time,
            Field.Type::DateTime,
            Field.Type::DateFormula,
            Field.Type::Option,
            Field.Type::Duration));
        Field.SetRange(Class, Field.Class::Normal);

        Field.SetFilter(TableNo, TableNoFilter);
        Field.SetFilter("No.", FieldNoFilter);
        if FieldSelection.Open(Field) then begin
            "Table No." := Field.TableNo;
            exit(Field."Field Caption");
        end;
        exit('');
    end;

    local procedure LookupFieldCaptionForApplyNewValues(): Text
    var
        WorkflowStepApply: Record "Workflow Step";
        WorkflowStepRevert: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        FilterForField: Text;
        FilterForTable: Text;
        Separator: Text[1];
        AddSeparator: Boolean;
    begin
        WorkflowStepApply.SetRange(Argument, ID);
        if WorkflowStepApply.FindFirst then begin
            WorkflowStepRevert.SetRange("Workflow Code", WorkflowStepApply."Workflow Code");
            WorkflowStepRevert.SetRange("Function Name", WorkflowResponseHandling.RevertValueForFieldCode);

            if WorkflowStepRevert.FindSet then
                repeat
                    WorkflowStepArgument.Get(WorkflowStepRevert.Argument);
                    if WorkflowStepArgument."Field No." <> 0 then begin
                        if AddSeparator then
                            Separator := '|';
                        AddSeparator := true;
                        FilterForTable += Separator + Format(WorkflowStepArgument."Table No.");
                        FilterForField += Separator + Format(WorkflowStepArgument."Field No.");
                    end;
                until WorkflowStepRevert.Next = 0;

            exit(LookupFieldCaption(FilterForTable, FilterForField));
        end;
        exit('');
    end;

    local procedure ValidateFieldCaption()
    var
        "Field": Record "Field";
    begin
        if TableFieldCaption <> '' then begin
            Field.SetRange(TableNo, "Table No.");
            Field.SetRange("Field Caption", TableFieldCaption);
            Field.FindFirst;
            "Field No." := Field."No."
        end else
            "Field No." := 0;

        CurrPage.Update(true);
    end;
}


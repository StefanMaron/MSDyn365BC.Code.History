page 11411 "Elec. Tax Declaration Card"
{
    Caption = 'Elec. Tax Declaration Card';
    PageType = Document;
    SourceTable = "Elec. Tax Declaration Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Declaration Type"; "Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Declaration TypeEditable";
                    ToolTip = 'Specifies whether the electronic declaration concerns a VAT or ICP declaration.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the electronic declaration that you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Declaration Period"; "Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Declaration PeriodEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the declaration period.';
                }
                field("Declaration Year"; "Declaration Year")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Declaration YearEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the declaration year.';
                }
                field("Message ID"; "Message ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the response message from the Tax authority.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the electronic declaration.';
                }
                field("Our Reference"; "Our Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Our ReferenceEditable";
                    ShowMandatory = true;
                    ToolTip = 'Specifies the unique identification for the electronic declaration.';
                }
                field("Date Created"; "Date Created")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the electronic declaration is created by the user.';
                }
                field("Date Submitted"; "Date Submitted")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the electronic declaration is submitted to the tax authority.';
                }
                field("Date Received"; "Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the response message from the tax authority for an electronic declaration is processed.';
                }
            }
            part(Control1000017; "Elec. Tax Decl. Line Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Declaration Type" = FIELD("Declaration Type"),
                              "Declaration No." = FIELD("No.");
                SubPageView = SORTING("Declaration Type", "Declaration No.", "Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Declaration")
            {
                Caption = '&Declaration';
                Image = VATStatement;
                separator(Action1000024)
                {
                }
                action(DownloadSubmissionMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Download Submission Message';
                    Image = MoveDown;
                    ToolTip = 'Download the XBRL message without the actual submission. For example, this can be helpful for troubleshooting submissions.';

                    trigger OnAction()
                    begin
                        DownloadSubmissionMessage();
                    end;
                }
                action("Response Messages")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Response Messages';
                    Enabled = ResponseMessageEnabled;
                    Image = Alerts;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Elec. Tax Decl. Response Msgs.";
                    RunPageLink = "Declaration Type" = FIELD("Declaration Type"),
                                  "Declaration No." = FIELD("No.");
                    RunPageView = SORTING("Declaration Type", "Declaration No.");
                    ToolTip = 'View the response messages from the tax authorities.';
                }
                action("Error Log")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Log';
                    Image = ErrorLog;
                    RunObject = Page "Elec. Tax Decl. Error Log";
                    RunPageLink = "Declaration Type" = FIELD("Declaration Type"),
                                  "Declaration No." = FIELD("No.");
                    RunPageView = SORTING("Declaration Type", "Declaration No.", "No.");
                    ToolTip = 'View all the errors for each electronic tax declaration with the status Error. The error information is obtained from the response messages of the tax authorities.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateElectronicTaxDeclaration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Electronic Tax Declaration';
                    Ellipsis = true;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create electronic VAT and ICP declarations, which you can submit them to the tax authorities.';

                    trigger OnAction()
                    var
                        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
                    begin
                        if Status > Status::Created then
                            Error(StatusErr);
                        TestField("Our Reference");

                        if ("Declaration Year" = 0) or ("Declaration Period" = "Declaration Period"::" ") then
                            Error(Text000, FieldCaption("Declaration Period"), FieldCaption("Declaration Year"));

                        ElecTaxDeclarationHeader := Rec;
                        ElecTaxDeclarationHeader.SetRecFilter;

                        case "Declaration Type" of
                            "Declaration Type"::"VAT Declaration":
                                REPORT.RunModal(REPORT::"Create Elec. VAT Declaration", true, false, ElecTaxDeclarationHeader);
                            "Declaration Type"::"ICP Declaration":
                                REPORT.RunModal(REPORT::"Create Elec. ICP Declaration", true, false, ElecTaxDeclarationHeader);
                        end;
                    end;
                }
                action(GenerateSubmissionMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Generate submission message.';
                    Ellipsis = true;
                    Enabled = SubmitEnabled;
                    Image = TestFile;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Generate the xbrl request without the actual submission.';

                    trigger OnAction()
                    begin
                        DownloadGeneratedSubmissionMessage();
                    end;
                }
                action(SubmitElectronicTaxDeclaration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Submit Electronic Tax Declaration';
                    Ellipsis = true;
                    Enabled = SubmitEnabled;
                    Image = TransmitElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Send the VAT and ICP declarations to the tax authorities.';

                    trigger OnAction()
                    var
                        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
                        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
                        EnvironmentInfo: Codeunit "Environment Information";
                        UseReqWindow: Boolean;
                    begin
                        ElecTaxDeclarationHeader := Rec;
                        ElecTaxDeclarationHeader.SetRecFilter();
                        ElecTaxDeclarationSetup.Get();
                        if ElecTaxDeclarationSetup."Use Certificate Setup" then
                            UseReqWindow := false
                        else
                            UseReqWindow := EnvironmentInfo.IsSaaS();
                        REPORT.RunModal(
                          REPORT::"Submit Elec. Tax Declaration", UseReqWindow, false, ElecTaxDeclarationHeader);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls;
    end;

    trigger OnInit()
    begin
        "Our ReferenceEditable" := true;
        "Declaration YearEditable" := true;
        "Declaration PeriodEditable" := true;
        "Declaration TypeEditable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateControls;
    end;

    trigger OnOpenPage()
    begin
        UpdateControls;
        OnActivateForm;
    end;

    var
        Text000: Label '%1 and %2 must be filled before the declaration can be created.';
        [InDataSet]
        "Declaration TypeEditable": Boolean;
        [InDataSet]
        "Declaration PeriodEditable": Boolean;
        [InDataSet]
        "Declaration YearEditable": Boolean;
        [InDataSet]
        "Our ReferenceEditable": Boolean;
        StatusErr: Label 'The report must have the status of " " or Created before you can create the report content.';
        SubmitEnabled: Boolean;
        ResponseMessageEnabled: Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        "Declaration TypeEditable" := (Status = Status::" ");
        "Declaration PeriodEditable" := (Status = Status::" ");
        "Declaration YearEditable" := (Status = Status::" ");
        "Our ReferenceEditable" := (Status = Status::" ");
        SubmitEnabled := (Status >= Status::Created);
        ResponseMessageEnabled := ("Message ID" <> '');
    end;

    local procedure OnActivateForm()
    begin
        UpdateControls;
    end;
}


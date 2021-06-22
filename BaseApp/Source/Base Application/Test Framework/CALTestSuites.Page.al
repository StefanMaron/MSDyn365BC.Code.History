page 130400 "CAL Test Suites"
{
    Caption = 'CAL Test Suites';
    PageType = List;
    SaveValues = true;
    SourceTable = "CAL Test Suite";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the test suite.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
                field("Update Test Coverage Map"; "Update Test Coverage Map")
                {
                    ApplicationArea = All;
                }
                field("Tests to Execute"; "Tests to Execute")
                {
                    ApplicationArea = All;
                }
                field(Failures; Failures)
                {
                    ApplicationArea = All;
                }
                field("Tests not Executed"; "Tests not Executed")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Test &Suite")
            {
                Caption = 'Test &Suite';
                action("&Run All")
                {
                    ApplicationArea = All;
                    Caption = '&Run All';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    var
                        CALTestSuite: Record "CAL Test Suite";
                        CALTestLine: Record "CAL Test Line";
                    begin
                        if CALTestSuite.FindSet then
                            repeat
                                CALTestLine.SetRange("Test Suite", CALTestSuite.Name);
                                if CALTestLine.FindFirst then
                                    CODEUNIT.Run(CODEUNIT::"CAL Test Runner", CALTestLine);
                            until CALTestSuite.Next = 0;
                        Commit();
                    end;
                }
                group(Setup)
                {
                    Caption = 'Setup';
                    Image = Setup;
                    action("E&xport")
                    {
                        ApplicationArea = All;
                        Caption = 'E&xport';
                        Promoted = true;
                        PromotedCategory = Process;

                        trigger OnAction()
                        begin
                            ExportTestSuiteSetup;
                        end;
                    }
                    action("I&mport")
                    {
                        ApplicationArea = All;
                        Caption = 'I&mport';

                        trigger OnAction()
                        begin
                            ImportTestSuiteSetup;
                        end;
                    }
                }
                separator(Separator)
                {
                    Caption = 'Separator';
                }
                group(Results)
                {
                    Caption = 'Results';
                    Image = Log;
                    action(Action16)
                    {
                        ApplicationArea = All;
                        Caption = 'E&xport';

                        trigger OnAction()
                        begin
                            ExportTestSuiteResult;
                        end;
                    }
                    action(Action24)
                    {
                        ApplicationArea = All;
                        Caption = 'I&mport';

                        trigger OnAction()
                        begin
                            ImportTestSuiteResult;
                        end;
                    }
                }
            }
        }
    }
}


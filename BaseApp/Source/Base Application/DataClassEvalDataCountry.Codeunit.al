codeunit 1752 "Data Class. Eval. Data Country"
{

    trigger OnRun()
    begin
    end;

    procedure ClassifyCountrySpecificTables()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        ClassifyEmployee;
        ClassifyPayableEmployeeLedgerEntry;
        ClassifyDetailedEmployeeLedgerEntry;
        ClassifyEmployeeLedgerEntry;
        ClassifyEmployeeRelative;
        ClassifyEmployeeQualification;
        ClassifyVATReportHeader;
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Employee Posting Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cause of Absence");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Constant Symbol");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Bank Pmt. Appl. Rule Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Text-to-Account Mapping Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Bank Statement Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Bank Statement Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Issued Bank Statement Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Issued Bank Statement Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Payment Order Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Payment Order Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Issued Payment Order Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Issued Payment Order Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cash Document Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cash Document Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted Cash Document Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted Cash Document Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cash Desk User");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cash Desk Event");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Currency Nominal Value");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cash Desk Cue");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Registration Log");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cash Desk Report Selections");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Uncertainty Payer Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Electronically Govern. Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Registration Country/Region");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Registr. Country/Region Route");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Perf. Country Curr. Exch. Rate");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Excel Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statement File Mapping");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Identifier");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Identifier Translate");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Statement Comment Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Statement Attachment");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Multiple Interest Calc. Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Detailed G/L Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Attribute Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Period");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Subst. Customer Posting Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Subst. Vendor Posting Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Multiple Interest Rate");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Non Deductible VAT Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posting Description");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posting Desc. Parameter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Detailed Fin. Charge Memo Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Detailed Iss.Fin.Ch. Memo Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Detailed Reminder Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Detailed Issued Reminder Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Industry Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Company Officials");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Vendor Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"User Setup Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"No. Series Link");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Sales Advance Letter Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Sales Advance Letter Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Sales Advance Letter Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Sales Adv. Payment Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Advance Link");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Purch. Advance Letter Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Purch. Advance Letter Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Purch. Advance Letter Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Advance Letter Line Relation");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Amount Line Adv. Payment");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Purchase Adv. Payment Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Advance Link Buffer - Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Classification Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Depreciation Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"FA Extended Posting Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"SKP Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"FA History Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Credits Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Credit Report Selections");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Credit Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Credit Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted Credit Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted Credit Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Intrastat Currency Exch. Rate");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statistic Indication");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Specific Movement");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Intrastat Delivery Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stat. Reporting Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VIES Declaration Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VIES Declaration Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Package Material");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Package Material");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stockkeeping Unit Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Whse. Net Change Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Export Acc. Schedule");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Filter Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Result Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Result Column");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Result Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Result Value");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Result History");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Extension");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Reverse Charge Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Reverse Charge Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::Commodity);
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Commodity Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Document Footer");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Control Report Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Control Report Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Control Report Section");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Ctrl.Rep. - VAT Entry Link");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"EET Service Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"EET Business Premises");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"EET Cash Register");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"EET Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"EET Entry Status");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Certificate CZ Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Reg. No. Srv Config");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Sales Header Archive");
    end;

    local procedure ClassifyPayableEmployeeLedgerEntry()
    var
        DummyPayableEmployeeLedgerEntry: Record "Payable Employee Ledger Entry";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payable Employee Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableEmployeeLedgerEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableEmployeeLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableEmployeeLedgerEntry.FieldNo(Amount));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyPayableEmployeeLedgerEntry.FieldNo("Employee Ledg. Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableEmployeeLedgerEntry.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableEmployeeLedgerEntry.FieldNo("Employee No."));
    end;

    local procedure ClassifyDetailedEmployeeLedgerEntry()
    var
        DummyDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed Employee Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Ledger Entry Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Application No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Unapplied by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo(Unapplied));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Applied Empl. Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Initial Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Initial Entry Global Dim. 2"));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Initial Entry Global Dim. 1"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Credit Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Debit Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Credit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Debit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Transaction No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Employee No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo(Amount));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(
          TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Employee Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedEmployeeLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyEmployeeLedgerEntry()
    var
        DummyEmployeeLedgerEntry: Record "Employee Ledger Entry";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Applying Entry"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Amount to Apply"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Payment Method Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Payment Reference"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Creditor No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Message to Recipient"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Closed by Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Transaction No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Bal. Account No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Bal. Account Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Applies-to ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Closed by Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Closed at Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Closed by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo(Open));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Applies-to Doc. No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Applies-to Doc. Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Salespers./Purch. Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Employee Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Exported to Payment File"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Employee No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyEmployeeRelative()
    var
        DummyEmployeeRelative: Record "Employee Relative";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Relative";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Relative's Employee No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Birth Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Last Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Middle Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("First Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Relative Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Employee No."));
    end;

    local procedure ClassifyEmployeeQualification()
    var
        DummyEmployeeQualification: Record "Employee Qualification";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Qualification";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Expiration Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Employee Status"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Course Grade"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo(Cost));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Institution/Company"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("To Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("From Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Qualification Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Employee No."));
    end;

    local procedure ClassifyEmployee()
    var
        DummyEmployee: Record Employee;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::Employee;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Image));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(IBAN));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Bank Account No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Bank Branch No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Company E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Pager));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Extension));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Termination Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Inactive Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo(Status));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Employment Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo(Gender));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Union Membership No."));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Union Code"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Social Security No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Birth Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Picture));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Mobile Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Last Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Middle Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("First Name"));
    end;

    local procedure ClassifyVATReportHeader()
    var
        DummyVATReportHeader: Record "VAT Report Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Report Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVATReportHeader.FieldNo("Submitted By"));
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"VAT Return Period");
    end;
}


codeunit 140002 "Library - Local Functionality"
{

    trigger OnRun()
    begin
    end;

#if not CLEAN25
    var
        LibraryUtility: Codeunit "Library - Utility";

    [Obsolete('Moved to IRS Forms', '25.0')]
    procedure CreateIRS1099FormBox(var IRS1099FormBox: Record "IRS 1099 Form-Box"; MinimumReportable: Decimal)
    begin
        IRS1099FormBox.Init();
        IRS1099FormBox.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(IRS1099FormBox.FieldNo(Code), DATABASE::"IRS 1099 Form-Box"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"IRS 1099 Form-Box", IRS1099FormBox.FieldNo(Code))));
        IRS1099FormBox.Validate(Description, IRS1099FormBox.Code);
        IRS1099FormBox.Validate("Minimum Reportable", MinimumReportable);
        IRS1099FormBox.Insert(true);
    end;

    [Obsolete('Moved to IRS Forms', '25.0')]
    procedure CreateIRS1099Adjustment(var IRS1099Adjustment: Record "IRS 1099 Adjustment"; VendorNo: Code[20]; IRS1099Code: Code[10]; Year: Integer; Amount: Decimal)
    begin
        IRS1099Adjustment.Init();
        IRS1099Adjustment.Validate("Vendor No.", VendorNo);
        IRS1099Adjustment.Validate("IRS 1099 Code", IRS1099Code);
        IRS1099Adjustment.Validate(Year, Year);
        IRS1099Adjustment.Validate(Amount, Amount);
        IRS1099Adjustment.Insert(true);
    end;
#endif
}
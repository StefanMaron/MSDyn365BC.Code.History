#pragma warning disable AS0090
#pragma warning disable AS0007
#pragma warning disable AS0125
#pragma warning disable AS0082
#pragma warning disable AS0064
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Format;

/// <summary>
/// Specifies how a structured data type should be interpreted and read into a draft.
/// </summary>
enum 6109 "E-Doc. Read into Draft" implements IStructuredFormatReader
{
    Extensible = true;
    DefaultImplementation = IStructuredFormatReader = "E-Doc. Unspecified Impl.";

    value(0; "Unspecified")
    {
        Caption = 'Unspecified';
        Implementation = IStructuredFormatReader = "E-Doc. Unspecified Impl.";
    }
    value(1; "Blank Draft")
    {
        Caption = 'Blank Draft';
        Implementation = IStructuredFormatReader = "E-Doc. Empty Draft";
    }
    value(2; "ADI")
    {
        Caption = 'ADI';
        Implementation = IStructuredFormatReader = "E-Document ADI Handler";
    }
    value(3; "PEPPOL")
    {
        Caption = 'PEPPOL';
        Implementation = IStructuredFormatReader = "E-Document PEPPOL Handler";
    }
}
#pragma warning restore AS0125
#pragma warning restore AS0082
#pragma warning restore AS0007
#pragma warning restore AS0090
#pragma warning restore AS0064
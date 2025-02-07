/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "WHLSLMetalCodeGenerator.h"

#if ENABLE(WEBGPU)

#include "WHLSLFunctionWriter.h"
#include "WHLSLTypeNamer.h"
#include <wtf/text/StringBuilder.h>

namespace WebCore {

namespace WHLSL {

namespace Metal {

static String generateMetalCodeShared(String&& metalTypes, String&& metalFunctions)
{
    StringBuilder stringBuilder;
    stringBuilder.append("#include <metal_stdlib>\n");
    stringBuilder.append("#include <metal_atomic>\n");
    stringBuilder.append("#include <metal_math>\n");
    stringBuilder.append("#include <metal_relational>\n");
    stringBuilder.append("#include <metal_compute>\n");
    stringBuilder.append("#include <metal_texture>\n");
    stringBuilder.append("\n");
    stringBuilder.append("using namespace metal;\n"); // FIXME: Probably should qualify all calls to built-in functions, instead of using this line.
    stringBuilder.append("\n");

    stringBuilder.append(WTFMove(metalTypes));
    stringBuilder.append(WTFMove(metalFunctions));
    return stringBuilder.toString();
}

RenderMetalCode generateMetalCode(Program& program, MatchedRenderSemantics&& matchedSemantics, Layout& layout)
{
    TypeNamer typeNamer(program);
    auto metalTypes = typeNamer.metalTypes();
    auto metalFunctions = Metal::metalFunctions(program, typeNamer, WTFMove(matchedSemantics), layout);
    auto metalCode = generateMetalCodeShared(WTFMove(metalTypes), WTFMove(metalFunctions.metalSource));
    return { WTFMove(metalCode), WTFMove(metalFunctions.vertexMappedBindGroups), WTFMove(metalFunctions.fragmentMappedBindGroups) };
}

ComputeMetalCode generateMetalCode(Program& program, MatchedComputeSemantics&& matchedSemantics, Layout& layout)
{
    TypeNamer typeNamer(program);
    auto metalTypes = typeNamer.metalTypes();
    auto metalFunctions = Metal::metalFunctions(program, typeNamer, WTFMove(matchedSemantics), layout);
    auto metalCode = generateMetalCodeShared(WTFMove(metalTypes), WTFMove(metalFunctions.metalSource));
    return { WTFMove(metalCode), WTFMove(metalFunctions.mappedBindGroups) };
}

}

}

}

#endif

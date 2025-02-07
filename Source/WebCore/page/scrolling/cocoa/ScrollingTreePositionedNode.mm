/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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

#import "config.h"
#import "ScrollingTreePositionedNode.h"

#if ENABLE(ASYNC_SCROLLING)

#import "Logging.h"
#import "ScrollingStatePositionedNode.h"
#import "ScrollingTree.h"
#import "ScrollingTreeScrollingNode.h"
#import <QuartzCore/CALayer.h>
#import <wtf/text/TextStream.h>

namespace WebCore {

Ref<ScrollingTreePositionedNode> ScrollingTreePositionedNode::create(ScrollingTree& scrollingTree, ScrollingNodeID nodeID)
{
    return adoptRef(*new ScrollingTreePositionedNode(scrollingTree, nodeID));
}

ScrollingTreePositionedNode::ScrollingTreePositionedNode(ScrollingTree& scrollingTree, ScrollingNodeID nodeID)
    : ScrollingTreeNode(scrollingTree, ScrollingNodeType::Positioned, nodeID)
{
}

ScrollingTreePositionedNode::~ScrollingTreePositionedNode() = default;

void ScrollingTreePositionedNode::commitStateBeforeChildren(const ScrollingStateNode& stateNode)
{
    const ScrollingStatePositionedNode& positionedStateNode = downcast<ScrollingStatePositionedNode>(stateNode);

    if (positionedStateNode.hasChangedProperty(ScrollingStateNode::Layer))
        m_layer = positionedStateNode.layer();

    if (positionedStateNode.hasChangedProperty(ScrollingStatePositionedNode::RelatedOverflowScrollingNodes))
        m_relatedOverflowScrollingNodes = positionedStateNode.relatedOverflowScrollingNodes();

    if (positionedStateNode.hasChangedProperty(ScrollingStatePositionedNode::LayoutConstraintData))
        m_constraints = positionedStateNode.layoutConstraints();
}

void ScrollingTreePositionedNode::applyLayerPositions(const FloatRect&, FloatSize& cumulativeDelta)
{
    FloatSize layerOffset; // FIXME: layerOffset needs to be computed by looking at scrolling tree deltas
    // in the overflow nodes that affect this node. Some of that may come in via cumulativeDelta.

    LOG_WITH_STREAM(Scrolling, stream << "ScrollingTreePositionedNode " << scrollingNodeID() << " applyLayerPositions: total overflow delta " << layerOffset);

    layerOffset += cumulativeDelta;
    // Stationary nodes move in the opposite direction.
    if (m_constraints.scrollPositioningBehavior() == ScrollPositioningBehavior::Stationary)
        layerOffset = -layerOffset;

    FloatPoint layerPosition = m_constraints.layerPositionAtLastLayout() - layerOffset;
    [m_layer _web_setLayerTopLeftPosition:layerPosition - m_constraints.alignmentOffset()];

    cumulativeDelta += layerPosition - m_constraints.layerPositionAtLastLayout();
}

void ScrollingTreePositionedNode::relatedNodeScrollPositionDidChange(const ScrollingTreeScrollingNode& changedNode, const FloatRect& layoutViewport, FloatSize& cumulativeDelta)
{
    UNUSED_PARAM(changedNode);
    // FIXME: This will avoid doing work if we can determine that changedNode doesn't affect this positioned node.
    applyLayerPositions(layoutViewport, cumulativeDelta);
}

void ScrollingTreePositionedNode::dumpProperties(TextStream& ts, ScrollingStateTreeAsTextBehavior behavior) const
{
    ts << "positioned node";
    ScrollingTreeNode::dumpProperties(ts, behavior);

    ts.dumpProperty("layout constraints", m_constraints);
    ts.dumpProperty("related overflow nodes", m_relatedOverflowScrollingNodes.size());

    if (behavior & ScrollingStateTreeAsTextBehaviorIncludeNodeIDs) {
        if (!m_relatedOverflowScrollingNodes.isEmpty()) {
            TextStream::GroupScope scope(ts);
            ts << "overflow nodes";
            for (auto nodeID : m_relatedOverflowScrollingNodes)
                ts << "\n" << indent << "nodeID " << nodeID;
        }
    }
}

} // namespace WebCore

#endif // ENABLE(ASYNC_SCROLLING)

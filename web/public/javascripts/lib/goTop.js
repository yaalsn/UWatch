GoTop = function() {
    this.config = {
        pageWidth: 960,
        nodeId: 'go-top',
        nodeWidth: 50,
        distanceToBottom: 120,
        distanceToPage: 20,
        hideRegionHeight: 90,
        zIndex: 100,
        text: ''
    };

    this.cache = {
        topLinkThread: null
    }
};

GoTop.prototype = {
    init: function(config) {
            this.config = config || this.config;
            var _self = this;

            // 滚动屏幕, 修改节点位置和显示状态
            //jQuery(window).scroll( function() {
            $(window).on('scrollstop', function(){
                _self._scrollScreen( { _self: _self} );
            });

            // 改变屏幕尺寸, 修改节点位置
            //jQuery(window).resize(function() {
            $(window).on('resize', function() {
                _self._resizeWindow( { _self: _self } );
            });

            // 在页面中插入节点
            _self._insertNode( {_self:_self} );
    },

    _insertNode: function(args) {
            var _self = args._self;

            // 插入节点并绑定节点事件, 当节点被点击, 用 0.4 秒的时间滚动到页面顶部
            var topLink = jQuery('<a id="' + _self.config.nodeId + '" href="#">' + _self.config.text + '</a>');
            topLink.click(function() {
                jQuery('html,body').animate({scrollTop: 0}, 400);
                return false;
            }).appendTo(jQuery('body'));

            // 节点到屏幕右边的距离
            var right = _self._getDistanceToBottom({_self:_self});

            // IE6 (不支持 position:fixed) 的样式
            if(/MSIE 6/i.test(navigator.userAgent)) {
                topLink.css({
                    'display': 'none',
                    'position': 'absolute',
                    'right': right + 'px'
                });

            // 其他浏览器的样式
            } else {
                topLink.css({
                    'display': 'none',
                    'position': 'fixed',
                    'right': right + 'px',
                    'top': (jQuery(window).height() - _self.config.distanceToBottom) + 'px',
                    'z-index': _self.config.zIndex
                });
            }
    },

    _scrollScreen: function(args) {
            var _self = args._self;
       
            // 当节点进入隐藏区域, 隐藏节点
            var topLink = jQuery('#' + _self.config.nodeId);
            if (jQuery(document).scrollTop() <= _self.config.hideRegionHeight) {
                clearTimeout(_self.cache.topLinkThread);
                topLink.hide();
                return;
            }

            // 在隐藏区域之外, IE6 中修改节点在页面中的位置, 并显示节点
            if (/MSIE 6/i.test(navigator.userAgent)) {
                clearTimeout(_self.cache.topLinkThread);
                topLink.hide();
 
                _self.cache.topLinkThread = setTimeout(function() {
                    var top = jQuery(document).scrollTop() + jQuery(window).height() - _self.config.distanceToBottom;
                    topLink.css({'top': top + 'px'}).fadeIn();
                }, 400);
        
            // 在隐藏区域之外, 其他浏览器显示节点
            } else {
                topLink.fadeIn();
            }
    },

    _resizeWindow: function(args) {
            var _self = args._self;

            var topLink = jQuery('#' + _self.config.nodeId);

            // 节点到屏幕右边的距离
            var right = _self._getDistanceToBottom({_self:_self});

            // 节点到屏幕顶部的距离
            var top = jQuery(window).height() - _self.config.distanceToBottom;

            // IE6 中使用到页面顶部的距离取代
            if (/MSIE 6/i.test(navigator.userAgent)) {
                top += jQuery(document).scrollTop();
            }

            // 重定义节点位置
            topLink.css({
                'right': right + 'px',
                'top': top + 'px'
            });
    },

    _getDistanceToBottom: function(args) {
           var _self = args._self;

           // 节点到屏幕右边的距离 = (屏幕宽度 - 页面宽度 + 1 "此处 1px 用于消除偏移" ) / 2 - 节点宽度 - 节点左边到页面右边的宽度 (20px), 如果到右边距离屏幕边界不小于 10px
           var right = parseInt((jQuery(window).width() - _self.config.pageWidth + 1)/2 - _self.config.nodeWidth - _self.config.distanceToPage, 10);
           if (right < 10) {
               right = 10;
           }

           return right;
    }
};

































































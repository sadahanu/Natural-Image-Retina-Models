#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 10 13:00:24 2017

@author: zhouyu
"""

import numpy as np
import itertools
"""
A net used to make synthesized retina responses to images
"""
class SyntheNet(object):
    
    def __init__(self, inputSize, Hidden_size, G_filter, sub_r = 1,GW = 1, b1 = .2, b2 = .2):
        self.params = {}
        self.params['D'] = inputSize
        self.params['H'] = Hidden_size
        self.params['subr'] = sub_r
        self.params['Gfi'] = G_filter #HX1 Gaussian filter for the center
        self.params['GW'] = GW # Gaussian filter weight
        self.params['b1'] = np.ones(Hidden_size)*b1
        self.params['b2'] = b2
    
    def gridSubunits(self):
        # reutrn a HXD2 subunit matrix 
        # return center of subunits
        D = self.params['D']
        r = self.params['subr']
        H = self.params['H']
        n = int(np.sqrt(H))
        subx = (np.linspace(r,D-r,n)).astype(int)
        suby = (np.linspace(r,D-r,n)).astype(int)
        return subx, suby
  
    
    def randSubunits(self, seed = 42):
        # return a HxD2 subunit matrix
        # return center of subunits
        D = self.params['D']
        #r = self.params['subr']
        H = self.params['H']
        n = int(np.sqrt(H))
        np.random.seed(seed)
        subx = np.random.randint(0,D-1,size = n)
        np.random.seed(seed)
        suby = np.random.randint(0,D-1,size = n)
        return subx, suby
    
    def getSubunitMatrix(self,subx, suby):
        sub = [(r[0],r[1]) for r in itertools.product(subx, suby)]
        r = self.params['subr']
        H = self.params['H']
        D = self.params['D']
        subunits = np.zeros((H,D,D))
        for i in xrange(H):
            subunits[i,max(0,sub[i][0]-r):min(D-1,sub[i][0]+r),
                     max(0,sub[i][1]-r):min(D-1,sub[i][1]+r)] = 1
        subunits = np.reshape(subunits,(H,-1))
        return subunits, sub
        
        
    def getResponses(self,X,subunitLoc = 'grid',activation = np.tanh,sterror = 0.0001):
        # return both synthesized responses and location of subunits
        if subunitLoc == 'grid':
            subx, suby = self.gridSubunits()
        else:
            subx, suby = self.randSubunits()
        subunits, center = self.getSubunitMatrix(subx,suby)
        G_filter = self.params['Gfi']  #HX1 Gaussian filter for the center
        GW = self.params['GW'] # Gaussian filter weight
        b1 = self.params['b1'] 
        b2 = self.params['b2']
        G_filter = self.params['Gfi'] 
        sub_resp = activation(X.dot(subunits.T)+b1) # tanh  = 2sig(2X)-1; #tanh' = 4(sig(2x)*(1-sig(2x)))
        resp = sub_resp.dot(G_filter)*GW+b2
        # sterror * mean(resp) is the random part
        resp = resp + np.random.randn(resp.shape[0],1)*sterror*np.mean(resp)
        resp = (resp-np.min(resp))/(np.max(resp) - np.min(resp))# scale to 0-1
        return resp, center, self.params['subr']